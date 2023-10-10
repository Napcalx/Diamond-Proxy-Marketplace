// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { LibDiamond } from "../libraries/LibDiamond.sol";

contract ERC721Facet {

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    function name() public view returns(string memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.name;
    }

    function symbol() public view returns(string memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.symbol;
    }

    function ownerOf(uint256 id) public view returns (address owner) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require((owner = ds.ownerOf[id]) != address(0), "NOT_MINTED");
        return ds.ownerOf[id];
    }

    function balanceOf(address owner) public view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(owner != address(0), "ZERO_ADDRESS");

        return ds.balanceOf[owner];
    }

    function tokenURI(uint256 id) public view  returns (string memory) {
        _requireMinted(id);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id)) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address spender, uint256 id) public {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        address owner = ds.ownerOf[id];

        require(msg.sender == owner || ds.isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        ds.getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address spender, bool approved) public {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.isApprovedForAll[msg.sender][spender] = approved;

        emit ApprovalForAll(msg.sender, spender, approved);
    }

    function isApprovedForAll(address owner, address spender) public view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.isApprovedForAll[owner][spender];
    }

    function safeMint(address to,uint256 id) public {
        mint(to, id);
    }

    function mint(address to, uint256 id) public virtual {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(to != address(0), "INVALID_RECIPIENT");

        require(ds.ownerOf[id] == address(0), "ALREADY_MINTED");
        beforeTokenTransfer(address(0), to, id);

        // Counter overflow is incredibly unrealistic.
        unchecked {
            ds.balanceOf[to]++;
        }

        ds.ownerOf[id] = to;

        emit Transfer(address(0), to, id);
        afterTokenTransfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        address owner = ds.ownerOf[id];

        beforeTokenTransfer(owner, address(0), id);

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            ds.balanceOf[owner]--;
        }

        delete ds.ownerOf[id];

        delete ds.getApproved[id];

        emit Transfer(owner, address(0), id);
        afterTokenTransfer(owner, address(0), id);
    }

    function transferFrom (
        address from,
        address to,
        uint256 id
    ) public {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(from == ds.ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || ds.isApprovedForAll[from][msg.sender] || msg.sender == ds.getApproved[id],
            "NOT_AUTHORIZED"
        );

        beforeTokenTransfer(from, to, id);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            ds.balanceOf[from]--;

            ds.balanceOf[to]++;
        }

        ds.ownerOf[id] = to;

        delete ds.getApproved[id];

        emit Transfer(from, to, id);
        afterTokenTransfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public {
        transferFrom(from, to, id);

        require(
            to.code.length == 0, "Unsafe Recipient");
    }

    function _requireMinted(uint256 id) internal view virtual {
        require ((id != 0), "ERC721: invalid token ID");
    }
    
     function beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}



