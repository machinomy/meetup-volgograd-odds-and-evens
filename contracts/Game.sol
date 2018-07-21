pragma solidity ^0.4.24;

// isOdd = 2: even
// isOdd = 1: odd
contract Game {
    address public partyA;
    address public partyB;
    uint256 public depositA;
    uint256 public depositB;
    bytes32 public commitmentA;
    bytes32 public commitmentB;

    uint8 nA;
    uint8 isOddA;
    uint8 nB;
    uint8 isOddB;

    event DidDeposit(address indexed party, uint256 value);
    event DidWithdraw(uint256 toA, uint256 toB);

    constructor (address _partyA, address _partyB) public {
        partyA = _partyA;
        partyB = _partyB;
    }

    function depositA () public payable {
        require(msg.sender == partyA);
        require(msg.value > 0);
        depositA = msg.value;
        emit DidDeposit(msg.sender, msg.value);
    }

    function depositB () public payable {
        require(msg.sender == partyB);
        require(msg.value > 0);
        depositB = msg.value;
        emit DidDeposit(msg.sender, msg.value);
    }

    function isDepositDone () public view returns (bool) {
        return depositA > 0 && depositA == depositB;
    }

    function commitA (bytes32 _commitment) public {
        require(msg.sender == partyA);
        require(isDepositDone());
        commitmentA = _commitment;
    }

    function commitB (bytes32 _commitment) public {
        require(msg.sender == partyB);
        require(isDepositDone());
        commitmentB = _commitment;
    }

    function isCommitmentDone () public view returns (bool) {
        return commitmentA != bytes32(0) && commitmentB != bytes32(0);
    }

    function revealA (uint8 _n, uint8 _isOdd, bytes32 _salt) public {
        require(isCommitmentDone());
        require(commitmentDigest(_n, _isOdd, _salt) == commitmentA);
        nA = _n;
        isOddA = _isOdd;
    }

    function revealB (uint8 _n, uint8 _isOdd, bytes32 _salt) public {
        require(isCommitmentDone());
        require(commitmentDigest(_n, _isOdd, _salt) == commitmentB);
        nB = _n;
        isOddB = _isOdd;
    }

    function isRevealDone () public view returns (bool) {
        return (isOddA != 0) && (isOddB != 0);
    }

    function withdraw () public {
        require(msg.sender == partyA || msg.sender == partyB);
        uint16 sum = nA + nB;
        uint8 isOdd;
        uint256 toA;
        uint256 toB;

        if (sum / 2 == 0) {
            isOdd = 2;
        } else {
            isOdd = 1;
        }

        if (isOddA == isOdd) {
            toA = toA + depositA;
            partyA.transfer(depositA);
        } else {
            toB = toB + depositA;
            partyB.transfer(depositA);
        }

        if (isOddB == isOdd) {
            toB = toB + depositB;
            partyB.transfer(depositB);
        } else {
            toA = toA + depositB;
            partyA.transfer(depositB);
        }

        emit DidWithdraw(toA, toB);
    }

    function commitmentDigest (uint8 _n, uint8 _isOdd, bytes32 _salt) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_n, _isOdd, _salt));
    }
}
