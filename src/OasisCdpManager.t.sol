pragma solidity >= 0.5.0;

import { DssDeployTestBase } from "dss-deploy/DssDeploy.t.base.sol";
import "./OasisCdpManager.sol";

contract FakeUser {
    function doGive(
        OasisCdpManager manager,
        address urn,
        address dst,
        bytes32 ilk
    ) public {
        manager.give(urn, dst, ilk);
    }

    function doFrob(
        OasisCdpManager manager,
        address urn,
        bytes32 ilk,
        int dink,
        int dart
    ) public {
        manager.frob(urn, ilk, dink, dart);
    }
}

contract OasisCdpManagerTest is DssDeployTestBase {
    OasisCdpManager manager;
    FakeUser user;

    function setUp() public {
        super.setUp();
        deploy();
        manager = new OasisCdpManager(address(vat));
        user = new FakeUser();
    }

    function testOpenCDP() public {
        address cdp = manager.open("ETH");
        assertEq(vat.can(manager.urns(address(this), "ETH"), address(manager)), 1);
        assertEq(manager.owns(cdp), address(this));
    }

    function testOpenCDPOtherAddress() public {
        address cdp = manager.open("ETH", address(123));
        assertEq(manager.owns(cdp), address(123));
    }

    function testFailOpenCDPZeroAddress() public {
        manager.open("ETH", address(0));
    }

    function testFailOpenOverride() public {
        manager.open("ETH", address(123));
        manager.open("ETH", address(123));
    }

    function testGiveCDP() public {
        address cdp = manager.open("ETH");
        manager.give(cdp, address(123), "ETH");
        assertEq(manager.owns(cdp), address(123));
    }

    function testGiveAllowed() public {
        address cdp = manager.open("ETH");
        manager.allow(cdp, address(user), 1);
        user.doGive(manager, cdp, address(123), "ETH");
        assertEq(manager.owns(cdp), address(123));
    }

    function testGiveManyTimes() public {
        address cdp = manager.open("ETH");
        manager.give(cdp, address(user), "ETH");
        user.doFrob(manager, cdp, "ETH", 0, 0);
        user.doGive(manager, cdp, address(this), "ETH");
        manager.frob(cdp, "ETH", 0, 0);
    }

    function testFailGiveNotAllowed() public {
        address cdp = manager.open("ETH");
        user.doGive(manager, cdp, address(123), "ETH");
    }

    function testFailGiveNotAllowed2() public {
        address cdp = manager.open("ETH");
        manager.allow(cdp, address(user), 1);
        manager.allow(cdp, address(user), 0);
        user.doGive(manager, cdp, address(123), "ETH");
    }

    function testFailGiveNotAllowed3() public {
        address cdp = manager.open("ETH");
        address cdp2 = manager.open("ETH");
        manager.allow(cdp2, address(user), 1);
        user.doGive(manager, cdp, address(123), "ETH");
    }

    function testFailGiveToZeroAddress() public {
        address cdp = manager.open("ETH");
        manager.give(cdp, address(0), "ETH");
    }

    function testFailGiveToSameOwner() public {
        address cdp = manager.open("ETH");
        manager.give(cdp, address(this), "ETH");
    }

    function testFailInvalidIlk() public {
        address cdp = manager.open("ETH");
        manager.give(cdp, address(123), "ZZZ");
    }

    function testFailOverride() public {
        address cdp = manager.open("ETH");
        manager.open("ETH", address(123));
        manager.give(cdp, address(123), "ETH");
    }

    function testFailGiveResetAllowances() public {
        FakeUser tester = new FakeUser();
        address cdp = manager.open("ETH");

        manager.allow(cdp, address(tester), 1);
        tester.doFrob(manager, cdp, "ETH", 0, 0);

        manager.give(cdp, address(user), "ETH");
        tester.doFrob(manager, cdp, "ETH", 0, 0);
    }

    function testFrob() public {
        address cdp = manager.open("ETH");
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), 1 ether);
        ethJoin.join(manager.urns(address(this), "ETH"), 1 ether);
        manager.frob(cdp, "ETH", 1 ether, 50 ether);
        assertEq(vat.dai(manager.urns(address(this), "ETH")), 50 ether * ONE);
        assertEq(vat.dai(address(this)), 0);
        manager.move(cdp, address(this), 50 ether * ONE);
        assertEq(vat.dai(manager.urns(address(this), "ETH")), 0);
        assertEq(vat.dai(address(this)), 50 ether * ONE);
        assertEq(dai.balanceOf(address(this)), 0);
        vat.hope(address(daiJoin));
        daiJoin.exit(address(this), 50 ether);
        assertEq(dai.balanceOf(address(this)), 50 ether);
    }

    function testFrobDaiOtherDst() public {
        address cdp = manager.open("ETH");
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), 1 ether);
        ethJoin.join(manager.urns(address(this), "ETH"), 1 ether);
        manager.frob(cdp, address(this), "ETH", 1 ether, 50 ether);
        assertEq(vat.dai(manager.urns(address(this), "ETH")), 0);
        assertEq(vat.dai(address(this)), 50 ether * ONE);
    }

    function testFrobGemOtherDst() public {
        address cdp = manager.open("ETH");
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), 1 ether);
        ethJoin.join(manager.urns(address(this), "ETH"), 1 ether);
        manager.frob(cdp, "ETH", 1 ether, 50 ether);
        assertEq(vat.gem("ETH", manager.urns(address(this), "ETH")), 0);
        assertEq(vat.gem("ETH", address(this)), 0);
        manager.frob(cdp, address(this), "ETH", -int(1 ether), -int(50 ether));
        assertEq(vat.gem("ETH", manager.urns(address(this), "ETH")), 0);
        assertEq(vat.gem("ETH", address(this)), 1 ether);
    }

    function testFrobAllowed() public {
        address cdp = manager.open("ETH");
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), 1 ether);
        ethJoin.join(manager.urns(address(this), "ETH"), 1 ether);
        manager.allow(cdp, address(user), 1);
        user.doFrob(manager, cdp, "ETH", 1 ether, 50 ether);
        assertEq(vat.dai(manager.urns(address(this), "ETH")), 50 ether * ONE);
    }

    function testFailFrobNotAllowed() public {
        address cdp = manager.open("ETH");
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), 1 ether);
        ethJoin.join(manager.urns(address(this), "ETH"), 1 ether);
        user.doFrob(manager, cdp, "ETH", 1 ether, 50 ether);
    }

    function testFrobGetCollateralBack() public {
        address cdp = manager.open("ETH");
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), 1 ether);
        ethJoin.join(manager.urns(address(this), "ETH"), 1 ether);
        manager.frob(cdp, "ETH", 1 ether, 50 ether);
        manager.frob(cdp, "ETH", -int(1 ether), -int(50 ether));
        assertEq(vat.dai(address(this)), 0);
        assertEq(vat.gem("ETH", manager.urns(address(this), "ETH")), 1 ether);
        assertEq(vat.gem("ETH", address(this)), 0);
        manager.flux(cdp, address(this), "ETH", 1 ether);
        assertEq(vat.gem("ETH", manager.urns(address(this), "ETH")), 0);
        assertEq(vat.gem("ETH", address(this)), 1 ether);
        uint prevBalance = address(this).balance;
        ethJoin.exit(address(this), 1 ether);
        weth.withdraw(1 ether);
        assertEq(address(this).balance, prevBalance + 1 ether);
    }

    function testGetWrongCollateralBack() public {
        address cdp = manager.open("ETH");
        col.mint(1 ether);
        col.approve(address(colJoin), 1 ether);
        colJoin.join(manager.urns(address(this), "ETH"), 1 ether);
        assertEq(vat.gem("COL", manager.urns(address(this), "ETH")), 1 ether);
        assertEq(vat.gem("COL", address(this)), 0);
        manager.flux(cdp, address(this), "COL", 1 ether);
        assertEq(vat.gem("COL", manager.urns(address(this), "ETH")), 0);
        assertEq(vat.gem("COL", address(this)), 1 ether);
    }

    function testQuit() public {
        address cdp = manager.open("ETH");
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), 1 ether);
        ethJoin.join(manager.urns(address(this), "ETH"), 1 ether);
        manager.frob(cdp, "ETH", 1 ether, 50 ether);

        (uint ink, uint art) = vat.urns("ETH", manager.urns(address(this), "ETH"));
        assertEq(ink, 1 ether);
        assertEq(art, 50 ether);
        (ink, art) = vat.urns("ETH", address(this));
        assertEq(ink, 0);
        assertEq(art, 0);

        vat.hope(address(manager));
        manager.quit(cdp, address(this), "ETH");
        (ink, art) = vat.urns("ETH", manager.urns(address(this), "ETH"));
        assertEq(ink, 0);
        assertEq(art, 0);
        (ink, art) = vat.urns("ETH", address(this));
        assertEq(ink, 1 ether);
        assertEq(art, 50 ether);
    }
}
