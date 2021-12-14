const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TestCoin", function () {
  it("Test CaritaCoin deployment", async function () {
    const CaritaCoinLight = await ethers.getContractFactory("CaritaCoinLight");
    const coin = await CaritaCoinLight.deploy();
    await coin.deployed();

  });
});
