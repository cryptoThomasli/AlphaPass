//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AlphaNft is Ownable, ERC721A, ReentrancyGuard {
    uint256 public immutable maxQty = 1024;
    uint256 public immutable reserveQty = 300;
    uint256 public tokensReserved;
    // TODO: mintPrice to be decided
    uint256 public immutable mintPrice = 0.01 ether;
    uint256 public immutable maxMintPerAddr = 1;
    string private _baseTokenURI;

    // Flag whether address is minted or not
    mapping(address => bool) private _isMinted;

    //sale stages:
    //stage 0: init(no minting, only reserve)
    //stage 1: 200 whitelist mint
    //stage 2: 200 whitelist mint, 100 public mint
    //stage 3: 150 whitelist mint, 50 public mint
    //stage 4: only reserve
    uint8 public _stage = 0;
    uint256 public immutable maxQtyStage1 = 200;
    uint256 public immutable maxQtyStage2 = 300;
    uint256 public immutable maxQtyStage3 = 200;
    uint256 public _tokensMintedStage1 = 0;
    uint256 public _tokensMintedStage2 = 0;
    uint256 public _tokensMintedStage3 = 0;

    constructor(string memory baseURI)
        ERC721A("AlphaPass", "AlphaPass")
    {
        _baseTokenURI = baseURI;
    }

    function nextStage() external onlyOwner {
        require(stage <= 4, "Stage cannot be more than 4");
        stage++;
    }

    function reserve(address recipient, uint256 quantity) external onlyOwner {
        require(quantity > 0, "Quantity too low");
        uint256 totalsupply = totalSupply();
        require(totalsupply + quantity <= maxQty, "Exceed sales max limit");
        require(
            tokensReserved + quantity <= reserveQty,
            "Max reserve quantity exceeded"
        );

        _safeMint(recipient, quantity);
        tokensReserved += quantity;  
    }

    function whitelistMint(uint256 quantity, bytes memory signature) external payable nonReentrant {
        require(verify(signature, _msgSender()), "Verify failed");

        require(_stage == 1 || _stage == 2 || _stage == 3, "invalid stage");
        require(isStageMaxQtyExceed(quantity), "Exceed stage sales max limit");
        require(!_isMinted[_msgSender()], "User is minted");
        require(tx.origin == msg.sender, "Contracts not allowed");
        uint256 totalsupply = totalSupply();
        require(totalsupply + quantity <= maxQty, "Exceed sales max limit");
        require(
            numberMinted(msg.sender) + quantity <= maxMintPerAddr,
            "cannot mint this many"
        );

        uint256 cost;
        unchecked {
            cost = quantity * mintPrice;
        }
        require(msg.value == cost, "wrong payment");


        _isMinted[_msgSender()] = true;
        _safeMint(msg.sender, quantity);
        increaseTokensMinted(quantity);
    }

    function mint(uint256 quantity) external payable nonReentrant {
        require(_stage == 1 || _stage == 2 || _stage == 3, "invalid stage");
        require(isStageMaxQtyExceed(quantity), "Exceed stage sales max limit");
        require(!_isMinted[_msgSender()], "User is minted");
        require(tx.origin == msg.sender, "Contracts not allowed");
        uint256 totalsupply = totalSupply();
        require(totalsupply + quantity <= maxQty, "Exceed sales max limit");
        require(
            numberMinted(msg.sender) + quantity <= maxMintPerAddr,
            "cannot mint this many"
        );

        uint256 cost;
        unchecked {
            cost = quantity * mintPrice;
        }
        require(msg.value == cost, "wrong payment");

        _isMinted[_msgSender()] = true;
        _safeMint(msg.sender, quantity);
        increaseTokensMinted(quantity);
    }

    function verify(bytes memory signature, address target) internal view returns (bool) {
        bytes32 messageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", abi.encode(target))
        );

        return owner() == ECDSA.recover(messageHash, signature);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function isMinted(address addr) external view returns (bool) {
        return _isMinted[addr];
    }

    function isStageMaxQtyExceed(uint256 quantity) internal view returns (bool) {
        if (_stage == 1) {
            return _tokensMintedStage1 + quantity <= maxQtyStage1;
        }
        if (_stage == 2) {
            return _tokensMintedStage2 + quantity <= maxQtyStage2;
        }
        if (_stage == 3) {
            return _tokensMintedStage3 + quantity <= maxQtyStage3;
        }
        return false;
    }

    function increaseTokensMinted(uint256 quantity) internal {
        if (_stage == 1) {
            _tokensMintedStage1 += quantity;
        }
        if (_stage == 2) {
            _tokensMintedStage2 += quantity;
        }
        if (_stage == 3) {
            _tokensMintedStage3 += quantity;
        }
    }

    function withdraw() external nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        (bool success1, ) = payable(_msgSender()).call{ value: balance }("");
        require(success1, "Transfer failed.");
    }

}
