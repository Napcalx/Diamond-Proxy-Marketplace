// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/Diamond.sol";
import "../contracts/facets/ERC721MarketplaceFacet.sol";
import "./helpers/DiamondUtils.sol";
import "../contracts/facets/ERC721Facet.sol";
import "./helpers/Helpers.sol";

contract DiamondDeployer is DiamondUtils, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    ERC721Facet erc721F;
    ERC721MarketplaceFacet erc721mktF;

    uint256 currentOrderId;

    address user1;
    address user2;

    uint256 privKey1;
    uint256 privKey2;

    ERC721MarketplaceFacet.Order O;


    function  setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(
            address(this), 
            address(dCutFacet),
            "Admin"
        );
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        erc721mktF = new ERC721MarketplaceFacet();

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](3);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        cut[2] = (
            FacetCut({
                facetAddress: address(erc721mktF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("ERC721MarketplaceFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
    }

    function testOwnerCannotCreateOrder() public {
        O.seller = user2;
        switchSigner(user2);

        vm.expectRevert(ERC721MarketplaceFacet.NotOwner.selector);
        erc721mktF.createOrder(O);
    }

    function testNonApprovedNFT() public {
        switchSigner(user1);
        vm.expectRevert(ERC721MarketplaceFacet.NotApproved.selector);
        erc721mktF.createOrder(O);
    }

    function testMinPriceTooLow() public {
        switchSigner(user1);
        erc721F.setApprovalForAll(address(erc721mktF), true);
        O.price = 0;
        vm.expectRevert(ERC721MarketplaceFacet.MinPriceTooLow.selector);
        erc721mktF.createOrder(O);
    }

    function testDeadlineTooSoon() public {
        switchSigner(user1);
        erc721F.setApprovalForAll(address(erc721mktF), true);
        vm.expectRevert(ERC721MarketplaceFacet.DeadlineTooSoon.selector);
        erc721mktF.createOrder(O);
    }

    function testMinDuration() public {
        switchSigner(user1);
        erc721F.setApprovalForAll(address(erc721mktF), true);
        O.deadline = uint88(block.timestamp + 59 minutes);
        vm.expectRevert(ERC721MarketplaceFacet.MinDurationNotMet.selector);
        erc721mktF.createOrder(O);
    }

    function testEditNonValidOrder() public {
        switchSigner(user1);
        vm.expectRevert(ERC721MarketplaceFacet.OrderNotExisting.selector);
        erc721mktF.editOrder(1, 0, false);
    }

    function testEditOrderNotOwner() public {
        switchSigner(user1);
        erc721F.setApprovalForAll(address(erc721mktF), true);
        O.deadline = uint88(block.timestamp + 120 minutes);
        O.sig = (
            O.token,
            O.tokenId,
            O.price,
            O.deadline,
            O.seller,
            privKey1
        );
        uint256 OId = erc721mktF.createOrder(O);

        switchSigner(user2);
        vm.expectRevert(ERC721MarketplaceFacet.NotOwner.selector);
        erc721mktF.editOrder(OId, 0, false);
    }

    function testEditOrder() public {
        switchSigner(user1);
        erc721F.setApprovalForAll(address(erc721mktF), true);
        O.deadline = uint88(block.timestamp + 120 minutes);
        O.sig = (
            O.token,
            O.tokenId,
            O.price,
            O.deadline,
            O.seller,
            privKey1
        );
        uint256 OId = mPlace.createOrder(O);
        erc721mktF.editOrder(OId, 0.01 ether, false);

        ERC721MarketplaceFacet.Order memory k = erc721mktF.getOrder(OId);
        assertEq(k.price, 0.01 ether);
        assertEq(k.active, false);
    }

    function testExecuteNonValidOrder() public {
        switchSigner(user1);
        vm.expectRevert(ERC721MarketplaceFacet.OrderNotExisting.selector);
        erc721mktF.executeOrder(1);
    }

    function testExecuteExpiredOrder() public {
        switchSigner(user1);
        erc721F.setApprovalForAll(address(erc721mktF), true);
    }

    function testExecuteOrderNotActive() public {
        switchSigner(user1);
        erc721F.setApprovalForAll(address(erc721mktF), true);
        O.deadline = uint88(block.timestamp + 120 minutes);
        O.sig = (
            O.token,
            O.tokenId,
            O.price,
            O.deadline,
            O.seller,
            privKey1
        );
        uint256 OId = erc721mktF.createOrder(O);
        erc721mktF.editOrder(OId, 0.01 ether, false);
        switchSigner(user2);
        vm.expectRevert(ERC721MarketplaceFacet.OrderNotActive.selector);
        erc721mktF.executeOrder(OId);
    }

    function testExecutePriceNotMet() public {
        switchSigner(user1);
        erc721F.setApprovalForAll(address(erc721mktF), true);
        O.deadline = uint88(block.timestamp + 120 minutes);
        O.sig = (
            O.token,
            O.tokenId,
            O.price,
            O.deadline,
            O.seller,
            privKey1
        );
        uint256 OId = erc721mktF.createOrder(O);
        switchSigner(user2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC721MarketplaceFacet.PriceNotMet.selector,
                O.price - 0.9 ether
            )
        );
        erc721mktF.executeOrder{value: 0.9 ether}(OId);
    }

    function testExecutePriceMistMatch() public {
        switchSigner(user1);
        erc721F.setApprovalForAll(address(erc721mktF), true);
        O.deadline = uint88(block.timestamp + 120 minutes);
        O.sig = constructSig(
            O.token,
            O.tokenId,
            O.price,
            O.deadline,
            O.seller,
            privKey1
        );
        uint256 OId = erc721mktF.createOrder(O);
        switchSigner(user2);
        vm.expectRevert(
            abi.encodeWithSelector(ERC721MarketplaceFacet.PriceMisMatch.selector, O.price)
        );
        erc721mktF.executeOrder{value: 1.1 ether}(OId);
    }

    function testExecute() public {
        switchSigner(user1);
        erc721F.setApprovalForAll(address(erc721mktF), true);
        O.deadline = uint88(block.timestamp + 120 minutes);
        O.sig = (
            O.token,
            O.tokenId,
            O.price,
            O.deadline,
            O.seller,
            privKey1
        );
        uint256 OId = erc721mktF.createOrder(O);
        switchSigner(user2);
        uint256 user1BalanceBefore = user1.balance;

        erc721mktF.executeOrder{value: O.price}(OId);

        uint256 user1BalanceAfter = user1.balance;

        ERC721MarketplaceFacet.Order memory k = erc721mktF.getOrder(OId);
        assertEq(k.price, 1 ether);
        assertEq(k.active, false);

        assertEq(k.active, false);
        assertEq(ERC721(O.token).ownerOf(O.tokenId), user2);
        assertEq(user1BalanceAfter, user1BalanceBefore + O.price);
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}