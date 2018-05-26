pragma solidity 0.4.18;

import "@aragon/os/contracts/apps/AragonApp.sol";

contract CollectiveWallet is AragonApp {
  /// Events
  event CreateRequest( string description);

    struct Request {
        string objective;
        string description;
        address requester;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    string public groupName;
    address[] public currentOwners;
    mapping(address => bool) public owners;
    address[] public futureOwners;
    Request[] public requests;
    uint public minimumDeposit;

    modifier onlyOwners() {
        //require(owners[msg.sender]);
        _;
    }

    function CollectiveWallet () public {
        minimumDeposit = 10;
        groupName = "ETH Bs. As.";
        currentOwners.push(msg.sender);
        owners[msg.sender] = true;
    }

    function deposit() public payable onlyOwners {
        // Check that the transaction value is higher than the
        require(msg.value > 0);
    }

    function createRequest(string objective, string description, uint value, address recipient) public onlyOwners {
        require(compare(objective, "transfer") == 0 || compare(objective, "ownership") == 0);

        Request memory newRequest = Request({
            objective: objective,
            description: description,
            value: value,
            recipient: recipient,
            requester: msg.sender,
            complete: false,
            approvalCount: 0
        });

        requests.push(newRequest);
        CreateRequest("ok");
    }

    function approveRequest(uint index) public onlyOwners {
        Request storage request = requests[index];

        // Check that current Owner do not have a vote registered
        require(!request.approvals[msg.sender]);

        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }

    function finalizeRequest(uint index) public onlyOwners {
        Request storage request = requests[index];

        require(request.approvalCount > (currentOwners.length / 2));
        require(!request.complete);

        if (compare(request.objective, "transfer") == 0) {
            request.recipient.transfer(request.value);
        } else {
            owners[request.recipient] = true;
            futureOwners.push(request.recipient);
        }
        request.complete = true;
    }

    function aceptOwnership(uint index) public payable {
        // Check that is a valid aproved owner index
        require(futureOwners.length > index);

        // Check that only the approved adress can acept the ownership
        require(futureOwners[index] == msg.sender);

        // Check that the future owner sent the minimum
        require(msg.value >= minimumDeposit);

        address newOwner = futureOwners[index];
        owners[newOwner] = true;
        currentOwners.push(newOwner);
        delete futureOwners[index];
    }

    // Custom Getters
    function getRequestsCount() public view returns (uint) {
        return requests.length;
    }

    function getCurrentOwners(uint index) public view returns (address) {
        currentOwners.push(msg.sender);
        return currentOwners[index];
    }

    function getFutureOwners() public view returns (address[]) {
        return futureOwners;
    }

    function requests(uint index) public view onlyOwners returns (
        string, string, address, uint, address, bool, uint, bool){
        // Check that is a valid aproved owner index
        require(futureOwners.length > index);

        Request storage request = requests[index];

        return (
            request.objective,
            request.description,
            request.requester,
            request.value,
            request.recipient,
            request.complete,
            request.approvalCount,
            request.approvals[msg.sender]);
    }


    // Utility functions
    function compare(string _a, string _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;

        if (b.length < minLength) minLength = b.length;

        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
}
