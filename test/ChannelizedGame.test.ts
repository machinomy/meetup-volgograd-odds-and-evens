import * as chai from 'chai'
import ChannelizedGame from '../src/wrappers/ChannelizedGame'
import * as Web3 from 'web3'
import Gaser from '../src/Gasert'
import { BigNumber } from 'bignumber.js'

const assert = chai.assert
const web3 = (global as any).web3 as Web3
const gaser = new Gaser(web3)

// isOdd = 2: even
// isOdd = 1: odd

async function signCommitment (contract: ChannelizedGame.Contract, address: string, commitmentA: string, commitmentB: string): Promise<string> {
  let msg = await contract.combinedCommitmentDigest(commitmentA, commitmentB)
  return new Promise<string>((resolve, reject) => {
    web3.eth.sign(address, msg, (err, signature) => {
      err ? reject(err) : resolve(signature)
    })
  })
}

async function signReveal(game: ChannelizedGame.Contract, party: string, n: number, isOdd: number, salt: string): Promise<string> {
  let msg = await game.commitmentDigest(n, isOdd, salt)
  return new Promise<string>((resolve, reject) => {
    web3.eth.sign(party, msg, (err, signature) => {
      err ? reject(err) : resolve(signature)
    })
  })
}

async function signWithdraw(game: ChannelizedGame.Contract, party: string, toA: number, toB: number): Promise<string> {
  let msg = await game.withdrawDigest(toA, toB)
  return new Promise<string>((resolve, reject) => {
    web3.eth.sign(party, msg, (err, signature) => {
      err ? reject(err) : resolve(signature)
    })
  })
}

contract('ChannelizedGame', (accounts) => {
  const ChannelizedGame = artifacts.require<ChannelizedGame.Contract>('ChannelizedGame.sol')
  const partyA = accounts[0]
  const partyB = accounts[1]
  const alien = accounts[2]

  let game: ChannelizedGame.Contract

  before(async () => {
    game = await ChannelizedGame.new(partyA, partyB)
  })

  specify('flow', async () => {
    await game.depositA({ value: 100, from: partyA })
    await game.depositB({ value: 100, from: partyB })
    let isDepositDone = await game.isDepositDone()
    assert.isTrue(isDepositDone)

    let nA = 1 // odd
    let saltA = '0xdead'
    let isOddA = 1
    let commitmentA = await game.commitmentDigest(nA, isOddA, saltA)

    let nB = 2 // even
    let saltB = '0xcafe'
    let isOddB = 2
    let commitmentB = await game.commitmentDigest(nB, isOddB, saltB)

    let commitmentSignatureA = await signCommitment(game, partyA, commitmentA, commitmentB)
    let commitmentSignatureB = await signCommitment(game, partyB, commitmentA, commitmentB)
    await gaser.tx('channelized.commit', game.commit(commitmentA, commitmentB, commitmentSignatureA, commitmentSignatureB))

    let isCommitmentDone = await game.isCommitmentDone()
    assert.isTrue(isCommitmentDone)



    let revealSignatureA = await signReveal(game, partyA, nA, isOddA, saltA)
    await gaser.tx('channelized.revealA', game.revealA(nA, isOddA, saltA, revealSignatureA))

    let revealSignatureB = await signReveal(game, partyB, nB, isOddB, saltB)
    await gaser.tx('channelized.revealB', game.revealB(nB, isOddB, saltB, revealSignatureB))

    let isRevealDone = await game.isRevealDone()
    assert.isTrue(isRevealDone)

    let toA = 200
    let toB = 0

    let beforeA = web3.eth.getBalance(partyA) as BigNumber
    let beforeB = web3.eth.getBalance(partyB) as BigNumber

    let withdrawSigA = await signWithdraw(game, partyA, toA, toB)
    let withdrawSigB = await signWithdraw(game, partyB, toA, toB)
    let r = await gaser.tx('channelized.withdraw', game.withdraw(toA, toB, withdrawSigA, withdrawSigB, {from: alien}))

    assert.equal(r.logs[0].args.toA.toNumber(), 200)
    assert.equal(r.logs[0].args.toB.toNumber(), 0)

    let afterA = web3.eth.getBalance(partyA) as BigNumber
    let afterB = web3.eth.getBalance(partyB) as BigNumber

    assert.equal(afterA.minus(beforeA).toString(), '200')
    assert.equal(afterB.minus(beforeB).toString(), '0')
  })
})
