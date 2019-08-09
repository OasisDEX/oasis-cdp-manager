pragma solidity >= 0.5.0;

import "./OasisCdpManager.sol";

contract TestableOasisCdpManager is OasisCdpManager {
    constructor(address vat_) OasisCdpManager(vat_) public {
    }

    // Frob the cdp sending the generated DAI or collateral freed to a dst address.
    function frob(
        address usr,
        bytes32 ilk,
        address dst,
        int dink,
        int dart
    ) public note isAllowed(usr) {
        address urn = urns[usr][ilk];
        VatLike(vat).frob(
            ilk,
            urn,
            dink >= 0 ? urn : dst,
            dart <= 0 ? urn : dst,
            dink,
            dart
        );
    }

    // Transfer wad amount of cdp collateral from the cdp address to a dst address.
    function flux(
        address usr,
        bytes32 ilk,
        address dst,
        uint wad
    ) public note isAllowed(usr) {
        address urn = urns[usr][ilk];
        VatLike(vat).flux(ilk, urn, dst, wad);
    }

    // Transfer wad amount of DAI from the cdp address to a dst address.
    function move(
        address usr,
        bytes32 ilk,
        address dst,
        uint rad
    ) public note isAllowed(usr) {
        address urn = urns[usr][ilk];
        VatLike(vat).move(urn, dst, rad);
    }

}
