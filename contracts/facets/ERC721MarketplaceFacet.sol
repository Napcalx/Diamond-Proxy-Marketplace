// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import "lib/solmate/src/tokens/ERC721.sol";
// import "../libraries/LibDiamond.sol";

// contract ERC721MarketplaceFacet {

//     // Errors
//     error NotOwner();
//     error NotApproved();
//     error MinPriceTooLow();
//     error DeadlineTooSoon();
//     error MinDurationNotMet();
//     error InvalidSignature();
//     error OrderNotExisting();
//     error OrderNotActive();
//     error PriceNotMet(int256 difference);
//     error OrderExpired();
//     error PriceMisMatch(uint256 originalPrice);

//     address admin;

//     constructor () {
//         admin = msg.sender;
//     }

//     function useLibraryStruct(
//         address _token,
//         uint256 _tokenId,
//         uint256 _price,
//         uint88 _deadline,
//         address _seller,
//         bool _active
//     ) public pure returns (address, uint256, uint256, uint88, address, bool){
//         LibDiamond.Order memory order = libDiamond.getOrder(_token, _tokenId, _price, _deadline, _seller, _active);
//         return(
//             order.token,
//             order.tokenId,
//             order.price,
//             order.deadline,
//             order.seller,
//             order.active
//         );
//     }

//     function createOrder(Order calldata O) public returns (uint256 OId) {
//         LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
//         if(ERC721(O.token).ds.ownerOf(O.tokenId) != msg.sender) revert NotOwner();
//         if(!ERC721(O.token).ds.isApprovedForAll(msg.sender, address(this))) revert NotApproved();
//         if(O.price < 0.01 ether) revert MinPriceTooLow();
//         if(O.deadline < block.timestamp) revert DeadlineTooSoon();
//         if(O.deadline - block.timestamp < 60 minutes) revert MinDurationNotMet();

//         Order storage Od = ds.orders[ds.orderId];
//         Od.token = O.token;
//         Od.tokenId = O.tokenId;
//         Od.price = O.price;
//         Od.deadline = uint88(O.deadline);
//         Od.seller = msg.sender;
//         Od.active = true;

//         emit OrderCreated(ds.orderId, O);
//         OId = ds.orderId;
//         ds.orderId++;
//         return OId;
//     }

//     function executeOrder(uint256 _orderId) public payable {
//         LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
//         if(_orderId >= ds.orderId) revert OrderNotExisting();
//         Order storage order = ds.orders[_orderId];
//         if(order.deadline < block.timestamp) revert OrderExpired();
//         if(!order.active) revert OrderNotActive();
//         if(order.price < msg.value) revert PriceMisMatch(order.price);
//         if(order.price != msg.value) revert PriceNotMet(int256(order.price) - int256(msg.value));

//         order.active = false;

//         ERC721(order.token).transferFrom(
//             order.seller,
//             msg.sender,
//             order.tokenId
//         );

//         payable(order.seller).transfer(order.price);

//         emit OrderFulfilled(_orderId, order);
//     }

//     function editOrder(
//         uint256 _orderId, 
//         uint256 _newPrice,
//         bool _active
//     ) public {
//         LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
//         if(_orderId >= ds.orderId) revert OrderNotExisting();
//         Order storage order = ds.orders[_orderId];
//         if(order.seller != msg.sender) revert NotOwner();
//         order.active = _active;
//         order.price = _newPrice;
//         emit OrderEdited(_orderId, order);
//     }

//     function getOrder(
//         uint256 _orderId
//     ) public view returns (Order memory) {
//         return ds.orders[_orderId];
//     }
// }