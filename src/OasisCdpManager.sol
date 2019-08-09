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

    mapping (address => address) public owns;   // UrnHandler => Owner
    mapping (
        address => mapping (
            bytes32 => address
        )
    ) public urns;                              // Owner => Ilk => UrnHandler

    mapping (
        address => mapping (
            address => mapping (
                address => uint
            )
        )
    ) public allows;                            // Owner => UrnHandler => Allowed Addr => True/False

    event NewCdp(address indexed usr, address indexed own, bytes32 ilk, address urn);

    modifier isAllowed(address urn) {
        require(msg.sender == owns[urn] || allows[owns[urn]][urn][msg.sender] == 1, "not-allowed");
        _;
    }

    constructor(address vat_) public {
        vat = vat_;
    }

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "add-overflow");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0, "uint-to-int-overflow");
    }

    // Allow/disallow a dst address to manage the cdp.
    function allow(
        address urn,
        address usr,
        uint ok
    ) public {
        allows[msg.sender][urn][usr] = ok;
    }

    // Open a new cdp for the caller.
    function open(bytes32 ilk) public returns (address) {
        return open(ilk, msg.sender);
    }

    // Open a new cdp for a given usr address.
    function open(
        bytes32 ilk,
        address usr
    ) public note returns (address urn) {
        require(usr != address(0), "usr-address-0");
        require(urns[usr][ilk] == address(0), "cannot-override-urn");

        urn = address(new UrnHandler(vat));
        urns[usr][ilk] = urn;
        owns[urn] = usr;
        emit NewCdp(msg.sender, usr, ilk, urn);
    }

    // Give the cdp ownership to a dst address.
    function give(
        address urn,
        address dst,
        bytes32 ilk
    ) public note isAllowed(urn) {
        address owner = owns[urn];
        require(dst != address(0), "dst-address-0");
        require(dst != owns[urn], "dst-already-owner");
        require(urns[owner][ilk] == urn, "invalid-ilk-value");
        require(urns[dst][ilk] == address(0), "cannot-override-dst-urn");

        owns[urn] = dst;
        urns[dst][ilk] = urn;
        delete urns[owner][ilk];
    }

    // Frob the cdp keeping the generated DAI or collateral freed in the cdp urn address.
    function frob(
        address urn,
        bytes32 ilk,
        int dink,
        int dart
    ) public note isAllowed(urn) {
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
        address urn,
        address dst,
        bytes32 ilk,
        int dink,
        int dart
    ) public note isAllowed(urn) {
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
        address urn,
        address dst,
        bytes32 ilk,
        uint wad
    ) public note isAllowed(urn) {
        VatLike(vat).flux(ilk, urn, dst, wad);
    }

    // Transfer wad amount of DAI from the cdp address to a dst address.
    function move(
        address urn,
        address dst,
        uint rad
    ) public note isAllowed(urn) {
        VatLike(vat).move(urn, dst, rad);
    }

    // Quit the system, migrating the cdp (ink, art) to a different dst urn
    function quit(
        address urn,
        address dst,
        bytes32 ilk
    ) public note isAllowed(urn) {
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
