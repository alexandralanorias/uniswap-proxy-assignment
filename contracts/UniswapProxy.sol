// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Minimal interface for Uniswap V3 NonfungiblePositionManager
interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(MintParams calldata params)
    external
    payable
    returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
}

/// @notice Minimal WETH interface
interface IWETH9 {
    function deposit() external payable;
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}

/// @title UniswapProxy
/// @notice UUPS-upgradeable contract that accepts ERC20 + ETH deposits
///         and creates a Uniswap V3 liquidity position via NonfungiblePositionManager.mint()
contract UniswapProxy is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    INonfungiblePositionManager public positionManager;
    IWETH9 public weth;

    uint24 public poolFee;
    int24 public tickLower;
    int24 public tickUpper;

    event PositionCreated(
        uint256 indexed tokenId,
        address indexed token,
        uint128 liquidity,
        uint256 amountToken,
        uint256 amountETH
    );
    event PoolParamsUpdated(uint24 fee, int24 tickLower, int24 tickUpper);

    error ZeroAmount();
    error ZeroAddress();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializer (replaces constructor for proxy pattern)
    /// @param _positionManager Uniswap V3 NonfungiblePositionManager address
    /// @param _weth WETH9 address on the target network
    /// @param _poolFee Pool fee tier (e.g. 3000 = 0.3%)
    /// @param _tickLower Lower tick of the position range
    /// @param _tickUpper Upper tick of the position range
    function initialize(
        address _positionManager,
        address _weth,
        uint24 _poolFee,
        int24 _tickLower,
        int24 _tickUpper
    ) external initializer {
        if (_positionManager == address(0) || _weth == address(0)) revert ZeroAddress();

        __Ownable_init(msg.sender);

        positionManager = INonfungiblePositionManager(_positionManager);
        weth = IWETH9(_weth);
        poolFee = _poolFee;
        tickLower = _tickLower;
        tickUpper = _tickUpper;
    }

    /// @notice Deposit an ERC20 token + ETH (msg.value) and create a Uniswap V3 liquidity position.
    function depositAndCreatePosition(
        address token,
        uint256 amountToken
    ) external payable returns (uint256 tokenId, uint128 liquidity) {
        if (amountToken == 0 || msg.value == 0) revert ZeroAmount();
        if (token == address(0)) revert ZeroAddress();

        IERC20(token).safeTransferFrom(msg.sender, address(this), amountToken);

        weth.deposit{value: msg.value}();

        {
            address wethAddr = address(weth);

            (
                address token0,
                address token1,
                uint256 amount0Desired,
                uint256 amount1Desired
            ) = token < wethAddr
                ? (token, wethAddr, amountToken, msg.value)
                : (wethAddr, token, msg.value, amountToken);

            IERC20(token0).forceApprove(address(positionManager), amount0Desired);
            IERC20(token1).forceApprove(address(positionManager), amount1Desired);

            uint256 amount0Used;
            uint256 amount1Used;
            (tokenId, liquidity, amount0Used, amount1Used) = positionManager.mint(
                INonfungiblePositionManager.MintParams({
                    token0: token0,
                    token1: token1,
                    fee: poolFee,
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    amount0Desired: amount0Desired,
                    amount1Desired: amount1Desired,
                    amount0Min: 0,
                    amount1Min: 0,
                    recipient: msg.sender,
                    deadline: block.timestamp
                })
            );

            if (amount0Desired > amount0Used) IERC20(token0).safeTransfer(msg.sender, amount0Desired - amount0Used);
            if (amount1Desired > amount1Used) IERC20(token1).safeTransfer(msg.sender, amount1Desired - amount1Used);
        }

        emit PositionCreated(tokenId, token, liquidity, amountToken, msg.value);
    }

    /// @notice Update default pool parameters for future positions
    function setPoolParams(uint24 _poolFee, int24 _tickLower, int24 _tickUpper) external onlyOwner {
        poolFee = _poolFee;
        tickLower = _tickLower;
        tickUpper = _tickUpper;
        emit PoolParamsUpdated(_poolFee, _tickLower, _tickUpper);
    }

    /// @notice Allow contract to receive ETH (e.g. refunds from position manager)
    receive() external payable {}

    /// @notice Only the owner can authorize an upgrade
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}