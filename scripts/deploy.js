const { ethers } = require("hardhat");

async function main() {
  console.log("=== Deploying Mocks ===");

  const MockERC20 = await ethers.getContractFactory("MockERC20");
  const token = await MockERC20.deploy();
  await token.waitForDeployment();
  console.log("Token deployed at:", token.target);

  const MockWETH = await ethers.getContractFactory("MockWETH");
  const weth = await MockWETH.deploy();
  await weth.waitForDeployment();
  console.log("WETH deployed at:", weth.target);

  const MockPM = await ethers.getContractFactory("MockPositionManager");
  const pm = await MockPM.deploy();
  await pm.waitForDeployment();
  console.log("PositionManager deployed at:", pm.target);

  console.log("\n=== Deploying UUPS-Compatible UniswapProxy Implementation ===");
  const UniswapProxy = await ethers.getContractFactory("UniswapProxy");
  const implementation = await UniswapProxy.deploy();
  await implementation.waitForDeployment();
  console.log("Implementation deployed at:", implementation.target);

  console.log("\n=== Initializing Contract ===");
  const tx = await implementation.initialize(
    pm.target,
    weth.target,
    3000,
    -60000,
    60000
  );
  await tx.wait();
  console.log("Implementation initialized!\n");

  console.log("=== SUMMARY ===");
  console.log("Token address (use for minting/approvals):", token.target);
  console.log("WETH address:", weth.target);
  console.log("PositionManager address:", pm.target);
  console.log("Proxy/Implementation address (interact with this):", implementation.target);
  console.log("\nYou can verify this contract on zkSync explorer using the implementation address above.\n");

  return {
    token: token.target,
    weth: weth.target,
    pm: pm.target,
    proxy: implementation.target, // i treated implementation as a proxy for this assignment
  };
}

main().catch(console.error);