const { ethers } = require("hardhat");

async function main() {
  const proxyAddress = "0xa08D852c74d9C10eD2C29291C7C1e3facDbd4E13";
  const tokenAddress = "0x3B0A274220FE90E2f140B4b208f657487EeC225b";

  const [signer] = await ethers.getSigners();

  const token = await ethers.getContractAt("MockERC20", tokenAddress);
  const proxy = await ethers.getContractAt("UniswapProxy", proxyAddress);

  console.log("Minting tokens...");
  await token.mint(signer.address, ethers.parseEther("10"));

  console.log("Approving...");
  await token.approve(proxyAddress, ethers.parseEther("10"));

  console.log("Calling depositAndCreatePosition...");

  const tx = await proxy.depositAndCreatePosition(
    tokenAddress,
    ethers.parseEther("1"),
    { value: ethers.parseEther("0.001") }
  );

  await tx.wait();

  console.log("DONE! Transaction executed");
}

main().catch(console.error);