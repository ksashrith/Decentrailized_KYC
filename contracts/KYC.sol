pragma solidity ^0.8.14;

contract KYC {
    address Admin;

    struct Customer {
        string userName;
        string data;
        address bank;
        bool kycStatus;
        uint256 upVotes;
        uint256 downVotes;
    }

    struct Bank {
        string name;
        address ethAddress;
        string regNumber;
        uint256 complaintsReported;
        uint256 KYC_count;
        bool isAllowedToVote;
        bool isAllowedToAddKyc;
        bool isAllowedToAddCustomer;
    }

    struct KYCrequest {
        string userName;
        address bankAddress;
        string customerData;
    }

    constructor() {
        Admin = msg.sender;
    }

    mapping(string => Customer) customers;

    mapping(address => Bank) banks;

    mapping(string => KYCrequest) kycRequests;

    address[] allBankAddress;

    /*
    function to add customer
    */
    function addCustomer(string memory _userName, string memory _customerData)
        public
    {
        require(
            banks[msg.sender].isAllowedToAddCustomer,
            "this bank is not allowed to add customer"
        );
        require(
            customers[_userName].bank == address(0),
            "Customer is already present, please call modifyCustomer to edit the customer data"
        );
        customers[_userName] = Customer(
            _userName,
            _customerData,
            msg.sender,
            false,
            0,
            0
        );
    }

    /*
    function to view a particular customer
    */
    function viewCustomer(string memory _userName)
        public
        view
        returns (
            string memory,
            string memory,
            address
        )
    {
        require(
            customers[_userName].bank != address(0),
            "Customer is not present in the database"
        );
        return (
            customers[_userName].userName,
            customers[_userName].data,
            customers[_userName].bank
        );
    }

    /*
    function to modify customer and resetting the customer data , upvotes and downvotes
    */
    function modifyCustomer(
        string memory _userName,
        string memory _newcustomerData
    ) public {
        require(
            customers[_userName].bank != address(0),
            "Customer is not present in the database"
        );
        delete kycRequests[_userName];
        customers[_userName].data = _newcustomerData;
        customers[_userName].upVotes = 0;
        customers[_userName].downVotes = 0;
    }

    /*
    function to add Kyc request for a customer, only if the bank is 
    allowed to add kyc request
    */
    function addKYCrequest(string memory _userName, string memory _customerData)
        public
    {
        require(
            banks[msg.sender].isAllowedToAddKyc,
            "This bank is not allowed to process any KYC kycRequests"
        );
        require(
            kycRequests[_userName].bankAddress != address(0),
            "this customer is already in process"
        );
        banks[msg.sender].KYC_count++;
        kycRequests[_userName] = KYCrequest(
            _userName,
            msg.sender,
            _customerData
        );
    }

    /*
    function to remove kyc request
    */
    function removeKYCrequest(string memory _customerName) public {
        require(
            kycRequests[_customerName].bankAddress == msg.sender,
            " bank is not allowed to remove the request for this customer "
        );
        delete kycRequests[_customerName];
    }

    /*
    function to upVote a customer by any bank
    */
    function upVoteCustomer(string memory _customerName) public {
        require(
            banks[msg.sender].isAllowedToVote,
            "This bank is not allowed to vote"
        );
        require(
            customers[_customerName].bank != address(0),
            "Customer is not present in the database"
        );
        customers[_customerName].upVotes++;
    }

    /*
    function to downVote a customer by any bank, if downVotes are greater than upVotes
    or 1/3rd of banks have downVoted the customer, then the kyc status of the customer
    will be set to false
    */
    function downVoteCustomer(string memory _customerName) public {
        require(
            banks[msg.sender].isAllowedToVote,
            "This bank is not allowed to vote"
        );
        require(
            customers[_customerName].bank != address(0),
            "Customer is not present in the database"
        );
        customers[_customerName].downVotes++;
        Customer memory tempCust = customers[_customerName];
        customers[_customerName].kycStatus = ((tempCust.upVotes >
            tempCust.downVotes) &&
            (tempCust.downVotes < allBankAddress.length / 3));
    }

    /*
    function to return the number of complaints reported on any bank
    */
    function getBankComplaints(address bank) public view returns (uint256) {
        require(
            banks[bank].ethAddress != address(0),
            " Bank not found in the database"
        );
        return banks[bank].complaintsReported;
    }

    /*
    function to view the details of an bank
    */
    function viewBankDetails(address bank)
        public
        view
        returns (
            string memory,
            string memory,
            uint256,
            uint256,
            bool,
            bool,
            bool
        )
    {
        require(
            banks[bank].ethAddress != address(0),
            " Bank not found in the database"
        );
        Bank memory tempBank = banks[bank];
        return (
            tempBank.name,
            tempBank.regNumber,
            tempBank.KYC_count,
            tempBank.complaintsReported,
            tempBank.isAllowedToAddCustomer,
            tempBank.isAllowedToAddKyc,
            tempBank.isAllowedToVote
        );
    }

    /*
    function to  report a bank, if a bank has been reported by 1/3rd of
    total banks then that bank will be disallowed to vote ,
    also calling the modifyBankRightsToVote function
    */
    function reportBank(address bankAddress) public {
        require(
            banks[bankAddress].ethAddress != address(0),
            "Bank not found in the database"
        );
        banks[bankAddress].complaintsReported++;
        modifyBankRightsToVote(
            bankAddress,
            (banks[bankAddress].complaintsReported < allBankAddress.length / 3)
        );
    }

    /*
    function to  add a bank by the Admin
    */
    function addBank(
        string memory bankName,
        address bankAddress,
        string memory regNumber
    ) public {
        require(msg.sender == Admin, "Bank can only be added by the Admin");
        require(
            !nameAlreadyExists(banks[bankAddress].name, bankName),
            "Bankname already present"
        );
        require(
            !nameAlreadyExists(banks[bankAddress].regNumber, regNumber),
            "Register number already exists"
        );
        banks[bankAddress] = Bank(
            bankName,
            bankAddress,
            regNumber,
            0,
            0,
            true,
            true,
            true
        );
        allBankAddress.push(bankAddress);
    }

    /*
    function to  modify the voting rights of a bank
    */
    function modifyBankRightsToVote(address bankAddress, bool _isAllowedToVote)
        public
    {
        require(msg.sender == Admin, "Bank can only be added by the Admin");
        require(
            banks[bankAddress].ethAddress != address(0),
            "Bank does not exist in the database"
        );
        banks[bankAddress].isAllowedToVote = _isAllowedToVote;
    }

    /*
    function to  remove the bank by the Admin
    */
    function removeBank(address bankAddress) public {
        require(msg.sender == Admin, "Bank can only be added by the Admin");
        require(
            banks[bankAddress].ethAddress != address(0),
            "Bank does not exist in the database"
        );
        delete banks[bankAddress];
    }

    function nameAlreadyExists(string memory _existing, string memory _new)
        private
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked((_existing))) ==
            keccak256(abi.encodePacked((_new)));
    }

    // function isRegNumAlreadyExisting(string memory _regNumber) public view returns(bool){
    //     for(uint i=0;i<allBankAddress.length ;i++){
    //         string memory reg= banks[allBankAddress[i]].regNumber;
    //         if(keccak256(abi.encodePacked((reg))) == keccak256(abi.encodePacked((_regNumber)))){
    //             return true;
    //         }
    //     }
    //     return false;
    // }

    /*
    function to  block all rights of the bank
    */
    function blockBankRights(address bankAddress) public {
        require(
            banks[bankAddress].ethAddress != address(0),
            "bank does not exist"
        );
        banks[bankAddress].isAllowedToAddKyc = false;
        banks[bankAddress].isAllowedToAddCustomer = false;
    }
}
