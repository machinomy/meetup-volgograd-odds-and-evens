import * as chai from 'chai'
import ChannelizedGame from '../src/wrappers/ChannelizedGame'
import * as Web3 from 'web3'
import Gaser from '../src/Gasert'

const assert = chai.assert
const web3 = (global as any).web3 as Web3
const gaser = new Gaser(web3)

// isOdd = 2: even
// isOdd = 1: odd

async function signCommitment (address: string, msg: string): Promise<string> {
  return new Promise<string>((resolve, reject) => {
    web3.eth.sign(address, msg, (err, signature) => {
      err ? reject(err) : resolve(signature)
    })
  })
}

contract('Game', (accounts) => {
  const ChannelizedGame = artifacts.require<ChannelizedGame.Contract>('Game.sol')
  const partyA = accounts[0]
  const partyB = accounts[1]

  let game: ChannelizedGame.Contract

  before(async () => {
    game = await ChannelizedGame.new(partyA, partyB)
    console.log(game)
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
    let commitmentSignatureA = await signCommitment(partyA, commitmentA)
    console.log(commitmentSignatureA)
    console.log(commitmentA)
    console.log(game)
    let r = await game.commitmentAddress(commitmentA, commitmentSignatureA)
    console.log('address', r)
    console.log(partyA)
    // await gaser.tx('channelized.commitA', game.commitA(commitmentA, commitmentSignatureA))
    //
    // let nB = 2 // even
    // let saltB = '0xcafe'
    // let isOddB = 2
    // let commitmentB = await game.commitmentDigest(nB, isOddB, saltB)
    // await gaser.tx('game.commitB', game.commitB(commitmentB, { from: partyB }))
    //
    // let isCommitmentDone = await game.isCommitmentDone()
    // assert.isTrue(isCommitmentDone)
    //
    // await gaser.tx('game.revealA', game.revealA(nA, isOddA, saltA, { from: partyA }))
    // await gaser.tx('game.revealB', game.revealB(nB, isOddB, saltB, { from: partyB }))
    //
    // let isRevealDone = await game.isRevealDone()
    // assert.isTrue(isRevealDone)
    //
    // let r = await gaser.tx('game.withdraw', game.withdraw({ from: partyB }))
    // let toA = r.logs[0].args.toA
    // let toB = r.logs[0].args.toB
    //
    // assert.equal(toA.toNumber(), 200)
    // assert.equal(toB.toNumber(), 0)
  })
})
