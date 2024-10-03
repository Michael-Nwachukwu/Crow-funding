// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract Crowdfunding {
    /// @notice The bool variable that is used to prevent reentrancy attacks by ensuring the function is not already being executed.
    bool entered;
    // owner variable
    address owner;

    /** 
     * @dev Constructor that sets the contract deployer as the owner.
    */
    constructor(){
        owner = msg.sender;
    }

    /** 
     * @notice Custom modifier that requires the function is called by the contract's owner.
    */
    modifier onlyOwner {
        require(owner == msg.sender, "You are not the owner");
        _;
    }

    /** 
     * @notice Custom modifier that prevents a function from being called more than once until it has finished execution.
    */
    modifier customReentrancyGuard() {
        require(!entered);
        entered = true;
        _;
        entered = false;
    }

    /** 
     * @notice Structure for campaigns. Contains details about each campaign such as creator's address, name, description, benefactor's address, goal amount, duration and the amount raised so far.
    */
    struct Campaign {
        address creator;
        string name;
        string description;
        address benefactor;
        uint goal;
        uint duration;
        uint amountRaised;
        bool ended;
    }

    /** 
     * @notice An array of campaigns that have been created by users.
    */
    Campaign[] public campaigns;
    
    event CampaignCreated(address indexed creator, Campaign);
    event Donation (address indexed donor, uint amount, uint campaign);
    event CampaignEnded(uint index, address benefactor, uint amount);

    /** 
     * @notice Create a new campaign with the details provided by the user. The function takes in parameters such as name of the campaign, description, benefactor's address, goal amount and duration.
    */
    function createCampaign(string memory _name, string memory _description, address _benefactor, uint _goal, uint _duration) public {

        uint duration = block.timestamp + _duration;

        Campaign memory campaign = Campaign({
            creator: msg.sender,
            name: _name,
            description: _description,
            benefactor: _benefactor,
            goal: _goal,
            duration: duration,
            amountRaised: 0,
            ended: false
        });
        campaigns.push(campaign);
        emit CampaignCreated(msg.sender, campaign);
    }

    /** 
     * @notice Get an array of campaigns that were created by the current caller. This function returns an array of Campaign structs.
    */
    function getUserCampaigns() public view returns (Campaign[] memory) {
        uint count = 0;
        
        // First, count the number of campaigns by this user
        for (uint i = 0; i < campaigns.length; i++) {
            if (campaigns[i].creator == msg.sender) {
                count++;
            }
        }
        
        // Create an array to hold the user's campaigns
        Campaign[] memory userCampaigns = new Campaign[](count);
        
        // Fill the array with the user's campaigns
        uint index = 0;
        for (uint i = 0; i < campaigns.length; i++) {
            if (campaigns[i].creator == msg.sender) {
                userCampaigns[index] = campaigns[i];
                index++;
            }
        }
        
        return userCampaigns;
    }


    /** 
     * @notice Get the count of all campaigns that were created by the current caller. This is done by returning an uint which represents the length of the array.
    */
    function getCampaignCount() public view returns (uint) {
        return campaigns.length;
    }

    /** 
     * @notice Get all the details about a specific campaign based on its index in the array of campaigns. The returned value is a Campaign struct which contains all information about the campaign.
    */
    function getCampaignBalance(uint _i) public view returns (uint) {
        return campaigns[_i].amountRaised;
    }

    /** 
     * @notice Get the amount raised for a specific campaign based on its index in the array of campaigns. The returned value is an uint which represents the total amount raised so far.
    */
    function getCampaignDetails(uint _i) public view returns (Campaign memory) {
        return campaigns[_i];
    }

    /** 
     * @notice Allow users to contribute to a specific campaign. The function takes in an uint parameter which represents the index of the campaign they want to donate to. After ensuring that the duration has not passed, it adds the value sent with the transaction to the total amount raised for that campaign and emits a Donation event.
    */
    function donate(uint _i) public payable {

        Campaign storage campaign = campaigns[_i];

        // Added a check to ensure the campaign index is valid.
        require(_i < campaigns.length, "Invalid campaign index");

        // Added a check to ensure duration of campaign has no telapsed
        require(campaign.duration > block.timestamp, "Campaign duration has elapsed");

        // Added a check to ensure the campaign has not ended
        require(campaign.ended != true, "This campaign has ended");
        
        // Check for potential overflow
        require(campaign.amountRaised + msg.value >= campaign.amountRaised, "Overflow prevented");
        
        // Donate to the campaign 
        campaign.amountRaised += msg.value;

        // emit donation event
        emit Donation(msg.sender, msg.value, _i);
    }

    /** 
     * @notice End a specific campaign. The owner of the contract can call this function to end a campaign after its duration has passed, ensuring all funds have been transferred to the benefactor's address. It also sets the campaign status ended to true and emits a CampaignEnded event.
    */
    function endCampaign(uint _i) public onlyOwner customReentrancyGuard {

        Campaign storage endedCampaign = campaigns[_i];

        require(endedCampaign.duration < block.timestamp, "Campaign duration has elapsed");

        // Added check to ensure that benefactor exists
        require(endedCampaign.benefactor != address(0), "Benefactor does not exist");

        uint256 amountToTransfer = endedCampaign.amountRaised;

        // Added check to ensure that campaign balance is not equal to 0
        require(amountToTransfer > 0, "No funds to transfer");

        // Mark campaign as ended
        endedCampaign.ended = true;

        // Reset the campaign before transfer to prevent reentrancy
        endedCampaign.amountRaised = 0;

        // Transfer funds
        (bool success, ) = payable(endedCampaign.benefactor).call{value: amountToTransfer}("");
        require(success, "Transfer failed");

        // Emit an event
        emit CampaignEnded(_i, endedCampaign.benefactor, amountToTransfer);

    }

    /** 
     * @notice Return the contract balance in wei. This is used for testing purposes.
    */
    function CheckContractBalance() public view returns (uint) {
        return address(this).balance;
    }

}