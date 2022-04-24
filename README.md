# contracts
contracts for the MINI project


## WIP protocol architecture plan

### token/auctions

- **MiniToken.sol** - the ERC721 Token. tokenURI serves base64 encoded json metadata containing the svg wrapped bmp image.
- **MiniDataRepository.sol** - data repository for on chain artwork. Artwork will be stored using SSTORE2 pattern, where each json metadata blob (including image) is deployed as a data only contract. This contract will store a mapping of sequential token IDs to data contract addresses. Note that this means the image selection is deterministic, and each mint of a token will be associated with a predefined id -> address mapping. Data will be inserted by curators (address whitelist). Construction of the encoded json blob should happen off-chain. This contract should also have a permissioned function to edit image data for emergency use (in case of malformed data), and some basic validation.
- **MiniAuctionHouse.sol** - Modified Zora/Nouns rolling automated auctions. Requires user settlement to trigger next auction.
