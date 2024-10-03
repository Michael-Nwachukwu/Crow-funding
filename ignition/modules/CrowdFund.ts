import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const CrowdfundingModule = buildModule("CrowdfundingModule", (m) => {

  const crowdFund = m.contract("Crowdfunding");

  return { crowdFund };
});

export default CrowdfundingModule;
