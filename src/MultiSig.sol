// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract MultiSig {
    //events
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(address indexed owner, uint256 indexed txIndex, address indexed to, uint256 value, bytes data);
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    //modifier for checking only owner
    modifier OnlyOwner()  {
        require(isOwner[msg.sender], "Not the owner");
        _;
    }

    //modifier for checking if transaction exists
    modifier txExist(uint256 _index) {
        require(_index < transactions.length, "transaction not exist");
        _;
    }

    //modifier for checking if transaction is not yet executed
    modifier txNotExecuted(uint256 _index) {
        require(!transactions[_index].executed, "transaction executed");
        _;
    }

    //modifier to check if an address has approved of the transaction or not
        modifier txNotApproved(uint _index) {
        require(!isTransactionConfirmed[_index][msg.sender], "transaction already confirmed");
        _;
    }

    address[] public owners;
    uint256 public numConfirmationsRequired;

    //mapping for owner address
    mapping(address => bool) public isOwner;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint16 numConfirmations;                // @audit Assuming a max of 65536 owners maxNumConfirmations <= 65536 = 2^8 => we can take uint16 for numconfirmations => Saves 1 extra slot of storage
    }

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isTransactionConfirmed;

    Transaction[] public transactions;
   // @audit Constructors can be marked as payable to save deployment gas
/**Payable functions cost less gas to execute, because the compiler does not have to add extra checks to ensure that no payment is provided. A constructor can be safely marked as payable, because only the deployer would be able to pass funds, and the project itself would not pass any funds.
**/
    constructor(address[] memory _owners, uint16 _numConfirmationsRequired) payable { 
        require(_owners.length > 0, "Insufficient Owners");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of confirmations"
        );
        uint len = _owners.length;
        for (uint i; i < len; ++i) {   // @audit preincrement consumes less gas than post increment, avoid initializing with default
            address owner = _owners[i];     

            if (owner == address(0)) {
                revert("Zero address cannot be owner");
            }
            if (isOwner[owner]) {
                revert("Owner not unique");
            }

            isOwner[owner] = true;
            owners.push(owner);
        }
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    // accepts ether transfers to the contract
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    // Submit transaction function
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public OnlyOwner {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 1
            })
        );
        isTransactionConfirmed[txIndex][msg.sender] = true;
        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function approveTransaction(
        uint256 _txIndex
    )
        public
        OnlyOwner
        txExist(_txIndex)
        txNotExecuted(_txIndex)
        txNotApproved(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isTransactionConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
        if (transaction.numConfirmations >= numConfirmationsRequired) {
            executeTransaction(_txIndex);                       // @audit Internal Function alled only once can be inlined to save gas
        }
    }

    // Revoke Transaction Confirmation
    function revokeConfirmation(
        uint256 _txIndex
    ) public OnlyOwner txExist(_txIndex) txNotExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(isTransactionConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations = transaction.numConfirmations - 1;  //  @audit Operator -= costs more gas than <x> = <x> - <y> for state variables
        isTransactionConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

        function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(
        uint256 _txIndex
    )
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint16 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    // function to execute a transaction
    function executeTransaction(
        uint256 _txIndex
    ) internal OnlyOwner txExist(_txIndex) txNotExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        if(!success){
            revert("Transaction Execution Failed");
        }
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

}