const GAS_LIMIT = 2700000

module.exports = {
    networks: {
        development: {
            network_id: "*",
            host: "localhost",
            port: 8545,
            gas: GAS_LIMIT
        },
    },
    solc: {
        optimizer: {
            enabled: true,
            runs: 200
        }
    }
}
