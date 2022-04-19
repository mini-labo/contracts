# contracts
contracts for the MINI project


## WIP protocol architecture plan

### token/auctions

- MiniToken.sol - the ERC721 Token. tokenURI serves base64 encoded json metadata containing the svg wrapped bmp image.
- MiniGallery.sol - data repository for on chain artwork. Artwork will be stored using SSTORE2 pattern, where each image is deployed as a data only contract. This contract will store a mapping of sequential token IDs to data contract addresses. Note that this means the image selection is deterministic, and each mint of a token will be associated with a predefined id -> address mapping.
- MiniAuctionHouse.sol - Modified Zora/Nouns rolling automated auctions. Requires user settlement to trigger next auction. Auctions will be pulled from the data repository (gallery) contract
