const hre = require("hardhat");

async function main() {
    const KYC = await hre.ethers.getContractFactory(
        "KYC"
    );


    const kycContract = await KYC.deploy();

    await kycContract.deployed();

    console.log("KYC contract deployed to: " + kycContract.address);
}

main().then(() => process.exit(0)).catch((error) => {
    console.log(error);
    process.exit(1);
})