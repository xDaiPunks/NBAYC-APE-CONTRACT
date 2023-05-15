// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NBAYC is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 public punkToken;

    bool public soulbound = true;

    uint256 public mintPrice = 8 ether;
    uint256 public punkPerMint = 500;
    uint256 public constant maxSupply = 10000;

    uint256 public claimStartDate;
    uint256 public claimEndDate;

    uint256 internal nonce = 0;
    uint256[maxSupply] internal indices;

    address payable public receiver;
    address[] private whitelistedAddresses;

    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public claimed;

    constructor(
        address payable _receiver,
        IERC20 _punkToken
    ) ERC721("Not Bored Ape Yacht Club", "NBAYC") {
        receiver = _receiver;
        punkToken = _punkToken;
    }

    function mint(uint256 amount) public payable nonReentrant {
        require(block.timestamp > claimEndDate, "Mint period not active");
        require(amount <= 20, "You can mint a maximum of 20 tokens at once");
        require(msg.value >= mintPrice.mul(amount), "Not enough funds to mint");
        require(totalSupply() + amount <= maxSupply, "Maximum supply reached");

        receiver.transfer(msg.value);

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, randomIndex());
            punkToken.transfer(msg.sender, punkPerMint);
        }
    }

    function claim() public nonReentrant {
        require(
            block.timestamp >= claimStartDate &&
                block.timestamp <= claimEndDate,
            "Claim period not active"
        );

        uint256 amount = whitelist[msg.sender];
        require(amount > 0, "You are not in the whitelist");
        require(totalSupply() + amount <= maxSupply, "Maximum supply reached");

        whitelist[msg.sender] = 0;
        claimed[msg.sender] = claimed[msg.sender].add(amount);

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, randomIndex());
            punkToken.transfer(msg.sender, punkPerMint);
        }
    }

    function ownerMint(uint256 amount) public onlyOwner {
        require(amount <= 20, "Owner can mint a maximum of 20 tokens at once");
        require(totalSupply() + amount <= maxSupply, "Maximum supply reached");

        // Transfer Punk tokens to the owner
        require(
            punkToken.transfer(msg.sender, punkPerMint.mul(amount)),
            "Transfer of Punk tokens failed"
        );

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, randomIndex());
        }
    }

    function withdrawERC20Tokens(
        address _tokenAddress,
        uint256 _amount
    ) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(
            token.balanceOf(address(this)) >= _amount,
            "Not enough tokens in the contract"
        );
        token.transfer(msg.sender, _amount);
    }

    function randomIndex() internal returns (uint256) {
        uint256 value = 0;
        uint256 totalSize = maxSupply - totalSupply();
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    nonce,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % totalSize;

        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        if (indices[totalSize - 1] == 0) {
            indices[index] = totalSize - 1;
        } else {
            indices[index] = indices[totalSize - 1];
        }
        nonce++;

        return value;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setReceiver(address payable newReceiver) public onlyOwner {
        receiver = newReceiver;
    }

    function setSoulbound(bool _soulbound) public onlyOwner {
        soulbound = _soulbound;
    }

    function setClaimDates(uint256 _start, uint256 _end) public onlyOwner {
        claimStartDate = _start;
        claimEndDate = _end;
    }

    function addToWhitelist(
        address[] memory users,
        uint256[] memory amounts
    ) public onlyOwner {
        require(
            users.length == amounts.length,
            "Users and amounts arrays must have the same length"
        );

        for (uint256 i = 0; i < users.length; i++) {
            if (whitelist[users[i]] == 0) {
                whitelistedAddresses.push(users[i]);
            }
            whitelist[users[i]] = amounts[i];
        }
    }

    function removeFromWhitelist(address[] memory users) public onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            whitelist[users[i]] = 0;

            // Remove from whitelistedAddresses
            for (uint256 j = 0; j < whitelistedAddresses.length; j++) {
                if (whitelistedAddresses[j] == users[i]) {
                    whitelistedAddresses[j] = whitelistedAddresses[
                        whitelistedAddresses.length - 1
                    ];
                    whitelistedAddresses.pop();
                    break;
                }
            }
        }
    }

    function removeAllFromWhitelist() public onlyOwner {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            whitelist[whitelistedAddresses[i]] = 0;
        }

        delete whitelistedAddresses;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://nft.nbayc.io/";
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(_tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        if (soulbound) {
            require(
                block.timestamp > claimEndDate,
                "Transfer period not active"
            );
        }
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        if (soulbound) {
            require(
                block.timestamp > claimEndDate,
                "Transfer period not active"
            );
        }
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        if (soulbound) {
            require(
                block.timestamp > claimEndDate,
                "Transfer period not active"
            );
        }
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function approve(address to, uint256 tokenId) public override {
        if (soulbound) {
            require(
                block.timestamp > claimEndDate,
                "Transfer period not active"
            );
        }
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address to, bool approved) public override {
        if (soulbound) {
            require(
                block.timestamp > claimEndDate,
                "Transfer period not active"
            );
        }
        super.setApprovalForAll(to, approved);
    }
}
