import * as chai from 'chai'

const assert = chai.assert

contract('Game', () => {
  const Game = artifacts.require('Game.sol')

  specify('foo', async () => {
    assert.equal(1, 1)
  })
})
