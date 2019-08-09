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

}
