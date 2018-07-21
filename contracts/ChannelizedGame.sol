pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ECRecovery.sol";


// isOdd = 2: even
// isOdd = 1: odd
contract ChannelizedGame {
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

    function commitA (bytes32 _commitment, bytes _signature) public {
        require(isDepositDone());
        require(commitmentAddress(_commitment, _signature) == partyA);
        commitmentA = _commitment;
    }

    function commitB (bytes32 _commitment, bytes _signature) public {
        require(isDepositDone());
        require(commitmentAddress(_commitment, _signature) == partyB);
        commitmentB = _commitment;
    }

    function commitmentAddress(bytes32 _commitment, bytes _signature) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(abi.encodePacked(prefix, _commitment));
        return ECRecovery.recover(hash, _signature);
    }

    function isCommitmentDone () public view returns (bool) {
        return commitmentA != bytes32(0) && commitmentB != bytes32(0);
    }

//    function revealA (
//        uint8 _n,
//        uint8 _isOdd,
//        bytes32 _salt,
//        bytes32 _signature)
//    public {
//        require(isCommitmentDone());
//        require(isValidCommitmentDigestA(_n, _isOdd, _salt, commitmentA, _signature));
//        nA = _n;
//        isOddA = _isOdd;
//    }
//
//    function revealB (uint8 _n, uint8 _isOdd, bytes32 _salt) public {
//        require(isCommitmentDone());
//        require(isValidCommitmentDigest(_n, _isOdd, _salt, commitmentB));
//        nB = _n;
//        isOddB = _isOdd;
//    }
//
//    function isRevealDone () public view returns (bool) {
//        return (isOddA != 0) && (isOddB != 0);
//    }
//
//    function withdraw (uint256 toA, uint256 toB, bytes32 _signatureA, bytes32 _signatureB) public {
//        require(isWithdraw(toA, toB, _signatureA));
//        require(isWithdraw(toA, toB, _signatureB));
//        partyA.transfer(toA);
//        partyB.transfer(toB);
//    }

    function commitmentDigest (uint8 _n, uint8 _isOdd, bytes32 _salt) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_n, _isOdd, _salt));
    }

    function recoveryCommitmentDigest (uint8 _n, uint8 _isOdd, bytes32 _salt) public pure returns (bytes32) {
        bytes32 digest = commitmentDigest(_n, _isOdd, _salt);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, digest));
    }
}
