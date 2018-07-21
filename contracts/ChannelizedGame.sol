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
    event DidCommit(bytes32 commitmentA, bytes32 commitmentB);
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

    function commit (bytes32 _commitmentA, bytes32 _commitmentB, bytes _signatureA, bytes _signatureB) public {
        require(isDepositDone());
        require(commitmentAddress(_commitmentA, _commitmentB, _signatureA) == partyA);
        require(commitmentAddress(_commitmentA, _commitmentB, _signatureB) == partyB);
        commitmentA = _commitmentA;
        commitmentB = _commitmentB;

        emit DidCommit(commitmentA, commitmentB);
    }

    function commitmentAddress(bytes32 _commitmentA, bytes32 _commitmentB, bytes _signature) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 m = keccak256(abi.encodePacked(_commitmentA, _commitmentB));
        bytes32 hash = keccak256(abi.encodePacked(prefix, m));
        return ECRecovery.recover(hash, _signature);
    }

    function isCommitmentDone () public view returns (bool) {
        return commitmentA != bytes32(0) && commitmentB != bytes32(0);
    }

    function revealA (
        uint8 _n,
        uint8 _isOdd,
        bytes32 _salt,
        bytes _signature)
    public {
        require(isCommitmentDone());
        require(recoveredReveal(_n, _isOdd, _salt, _signature) == partyA);
        nA = _n;
        isOddA = _isOdd;
    }

    function recoveredReveal(uint8 _n, uint8 _isOdd, bytes32 _salt, bytes _signature) public pure returns (address) {
        bytes32 hash = revealDigest(_n, _isOdd, _salt);
        return ECRecovery.recover(hash, _signature);
    }

    function revealB (
        uint8 _n,
        uint8 _isOdd,
        bytes32 _salt,
        bytes _signature)
    public {
        require(isCommitmentDone());
        require(recoveredReveal(_n, _isOdd, _salt, _signature) == partyB);
        nB = _n;
        isOddB = _isOdd;
    }

    function isRevealDone () public view returns (bool) {
        return (isOddA != 0) && (isOddB != 0);
    }

    function withdraw (uint256 toA, uint256 toB, bytes _signatureA, bytes _signatureB) public {
        require(isWithdraw(toA, toB, _signatureA) == partyA);
        require(isWithdraw(toA, toB, _signatureB) == partyB);
        partyA.transfer(toA);
        partyB.transfer(toB);

        emit DidWithdraw(toA, toB);
    }

    function withdrawDigest(uint256 _toA, uint256 _toB) public view returns (bytes32) {
        return keccak256(abi.encodePacked("w", address(this), _toA, _toB));
    }

    function isWithdraw(uint256 _toA, uint256 _toB, bytes _signature) public view returns (address) {
        bytes32 digest = withdrawDigest(_toA, _toB);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(abi.encodePacked(prefix, digest));
        return ECRecovery.recover(hash, _signature);
    }

    function commitmentDigest (uint8 _n, uint8 _isOdd, bytes32 _salt) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_n, _isOdd, _salt));
    }

    function combinedCommitmentDigest (bytes32 _a, bytes32 _b) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_a, _b));
    }

    function revealDigest(uint8 _n, uint8 _isOdd, bytes32 _salt) public pure returns (bytes32) {
        bytes32 digest = commitmentDigest(_n, _isOdd, _salt);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, digest));
    }
}
