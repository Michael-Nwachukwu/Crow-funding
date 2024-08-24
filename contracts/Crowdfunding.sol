// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract Crowdfunding {
    bool entered;
    // owner variable
    address owner;

    // constructor that sets the owner to msg.sender
    constructor(){
        owner = msg.sender;
    }

    // custom modifier that requires owner to be the tx caller
    modifier onlyOwner {
        require(owner == msg.sender, "You are not the owner");
        _;
    }

    // Modifier to prevent reentrancy attacks by ensuring the function is not already being executed
    modifier customReentrancyGuard() {
        require(!entered);
        entered = true;
        _;
        entered = false;
    }

    // A campaign structure, containing attributes of a campaign
    struct Campaign {
        address creator;
        string name;
        string description;
        address benefactor;
        uint goal;
        uint duration;
        uint amountRaised;
    }
 
    mapping (address => Campaign) UsersCampaigns;

    Campaign[] public campaigns;
    
    event CampaignCreated(Campaign);
    event Donation (address donor, uint amount, Campaign campaign);
    event CampaignEnded(uint index, address benefactor, uint amount);

    function createCampaign(string memory _name, string memory _description, address _benefactor, uint _goal, uint _duration) public onlyOwner {
        Campaign memory campaign = Campaign({
            creator: msg.sender,
            name: _name,
            description: _description,
            benefactor: _benefactor,
            goal: _goal,
            duration: _duration,
            amountRaised: 0
        });
        campaigns.push(campaign);
        emit CampaignCreated(campaign);
    }

    /*
        This function returns all campaigns created by the user who calls the function

        function getUsersCampaign() public view returns (Campaign memory) {
            for (uint i = 0; i < campaigns.length; i++) {
                if (campaigns[i].creator == msg.sender) {
                    return campaigns[i];
                }
            }
        }
    */

   // ANOTHER WAY TO DO THE ABOVE CODE IS TO USE THE MAPPING ABOVE DEPENDING ON WHICH COSTS LESS GAS

    function getUsersCampaign() public view returns (Campaign memory) {
        return UsersCampaigns[owner];
    }


    // Function to get the number of campaigns created by the array length
    function getCampaignCount() public view returns (uint) {
        return campaigns.length;
    }

    // Function to get the balance/amountRaised in a specified campaign, by the index
    function getCampaignBalance(uint _i) public view returns (uint) {
        return campaigns[_i].amountRaised;
    }

    // Function to get a specified campaigns details by the index
    function getCampaignDetails(uint _i) public view returns (Campaign memory) {
        return campaigns[_i];
    }

    // Function to donate to a campaign, we grab the capmign by the index and add the msg.value amount to the amount raised. Before that we check to make sure that the duration time has not yet passed. Then emitting a donations event
    function donate(uint _i) public payable {
        // Added a check to ensure the campaign index is valid.
        require(_i < campaigns.length, "Invalid campaign index");
        require(block.timestamp < campaigns[_i].duration, "Campaign duration has elapsed");

        Campaign storage destination = campaigns[_i];
        
        // Check for potential overflow
        require(destination.amountRaised + msg.value >= destination.amountRaised, "Overflow prevented");
        
        destination.amountRaised += msg.value;

        emit Donation(msg.sender, msg.value, campaigns[_i]);
    }

    // This function ends a campaign by transferring the raised amount to the benefactor and deleting the campaign from the array
    // It checks if the campaign duration has passed, if the benefactor address is valid, transfers the amount to the benefactor, and deletes the campaign
    // @param _i The index of the campaign to end
    function endCampaign(uint _i) public customReentrancyGuard {

        require(block.timestamp >= campaigns[_i].duration, "Campaign duration has elapsed");

        Campaign storage endedCampaign = campaigns[_i];
        require(endedCampaign.benefactor != address(0), "Campaign does not exist");

        uint256 amountToTransfer = endedCampaign.amountRaised;
        require(amountToTransfer > 0, "No funds to transfer");

        // Reset the campaign before transfer to prevent reentrancy
        endedCampaign.amountRaised = 0;

        // Transfer funds
        (bool success, ) = payable(endedCampaign.benefactor).call{value: amountToTransfer}("");
        require(success, "Transfer failed");

        // Emit an event
        emit CampaignEnded(_i, endedCampaign.benefactor, amountToTransfer);

        delete campaigns[_i];
    }

}