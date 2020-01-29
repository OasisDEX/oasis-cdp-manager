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

contract OasisCdpManager is LibNote {
    address public vat;

    mapping (
        address => mapping (
            bytes32 => address
        )
    ) public urns;  // Owner => Ilk => UrnHandler

    event NewCdp(address indexed usr, bytes32 indexed ilk, address indexed urn);

    constructor(address vat_) public {
        vat = vat_;
    }

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0);
    }

    // Open a new cdp for msg.sender address.
    function open(
        bytes32 ilk,
        address usr
    ) public returns (address urn) {
        require(usr != address(0), "usr-address-0");
        require(urns[msg.sender][ilk] == address(0), "cannot-override-urn");
        urn = address(new UrnHandler(vat));
        urns[msg.sender][ilk] = urn;

        emit NewCdp(msg.sender, ilk, urn);
    }

    // Frob the cdp keeping the generated DAI or collateral freed in the cdp urn address.
    function frob(
        bytes32 ilk,
        int dink,
        int dart
    ) public note {
        address urn = urns[msg.sender][ilk];
        VatLike(vat).frob(
            ilk,
            urn,
            urn,
            urn,
            dink,
            dart
        );
    }

    // Transfer wad amount of cdp collateral from the cdp address to a dst address.
    function flux(
        bytes32 ilk,
        address dst,
        uint wad
    ) public note {
        VatLike(vat).flux(ilk, urns[msg.sender][ilk], dst, wad);
    }

    // Transfer wad amount of cdp collateral from the cdp address to a dst address.
    // This function has the purpose to take away collateral from the system that doesn't correspond to the cdp but was sent there wrongly.
    function flux(
        bytes32 ilk,
        bytes32 ilkExtract,
        address dst,
        uint wad
    ) public note {
        // TODO: we may want to use a different note library here.  The current
        // note library will not log all the arguments.
        VatLike(vat).flux(ilkExtract, urns[msg.sender][ilk], dst, wad);
    }

    // Transfer rad amount of DAI from the cdp address to a dst address.
    function move(
        bytes32 ilk,
        address dst,
        uint rad
    ) public note {
        VatLike(vat).move(urns[msg.sender][ilk], dst, rad);
    }

    // Quit the system, migrating the msg.sender cdp (ink, art) to a msg.sender urn
    function quit(
        bytes32 ilk
    ) public note {
        address urn = urns[msg.sender][ilk];
        (uint ink, uint art) = VatLike(vat).urns(ilk, urn);
        VatLike(vat).fork(
            ilk,
            urn,
            msg.sender,
            toInt(ink),
            toInt(art)
        );
    }

    // Import a position from msg.sender urn to msg.sender cdp
    function enter(
        bytes32 ilk
    ) public note {
        address urn = urns[msg.sender][ilk];
        // TODO: make a PR that just calls open() here.
        require(urn != address(0), "not-existing-urn");
        (uint ink, uint art) = VatLike(vat).urns(ilk, msg.sender);
        VatLike(vat).fork(
            ilk,
            msg.sender,
            urn,
            toInt(ink),
            toInt(art)
        );
    }
}
