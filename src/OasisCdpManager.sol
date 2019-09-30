pragma solidity >= 0.5.0;

import "dss/lib.sol";

contract VatLike {
    function urns(bytes32, address) public view returns (uint, uint);
    function hope(address) public;
    function flux(bytes32, address, address, uint) public;
    function move(address, address, uint) public;
    function frob(bytes32, address, address, address, int, int) public;
    function fork(bytes32, address, address, int, int) public;
}

contract UrnHandler {
    constructor(address vat) public {
        VatLike(vat).hope(msg.sender);
    }
}

contract OasisCdpManager is DSNote {
    address                   public vat;

    mapping (
        address => mapping (
            bytes32 => address
        )
    ) public urns;                              // Owner => Ilk => UrnHandler

    event NewCdp(address indexed usr, address indexed own, bytes32 ilk, address urn);

    modifier isAllowed(address usr) {
        require(msg.sender == usr, "not-allowed");
        _;
    }

    function toInt(uint x) internal pure returns (int y) {
      y = int(x);
      require(y >= 0);
    }

    constructor(address vat_) public {
        vat = vat_;
    }

    // Open a new cdp for the caller.
    function open(bytes32 ilk) public {
        open(ilk, msg.sender);
    }

    // Open a new cdp for a given usr address.
    function open(
        bytes32 ilk,
        address usr
    ) public note {
        require(usr != address(0), "usr-address-0");
        require(urns[usr][ilk] == address(0), "cannot-override-urn");

        address urn = address(new UrnHandler(vat));
        urns[usr][ilk] = urn;
        emit NewCdp(msg.sender, usr, ilk, urn);
    }

    // Frob the cdp keeping the generated DAI or collateral freed in the cdp urn address.
    function frob(
        address usr,
        bytes32 ilk,
        int dink,
        int dart
    ) public note isAllowed(usr) {
        address urn = urns[usr][ilk];
        VatLike(vat).frob(
            ilk,
            urn,
            urn,
            urn,
            dink,
            dart
        );
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

    // Transfer wad amount of cdp collateral from the cdp address to a dst address.
    // This function has the purpose to take away collateral from the system that doesn't correspond to the cdp but was sent there wrongly.
    function flux(
        address usr,
        bytes32 usrIlk,
        bytes32 ilk,
        address dst,
        uint wad
    ) public note isAllowed(usr) {
        address urn = urns[usr][usrIlk];
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

    // Quit the system, migrating the cdp (ink, art) to a different dst urn
    function quit(
        address usr,
        bytes32 ilk,
        address dst
    ) public note isAllowed(usr) isAllowed(dst) {
        address urn = urns[usr][ilk];
        (uint ink, uint art) = VatLike(vat).urns(ilk, urn);
        VatLike(vat).fork(
            ilk,
            urn,
            dst,
            toInt(ink),
            toInt(art)
        );
    }

}
