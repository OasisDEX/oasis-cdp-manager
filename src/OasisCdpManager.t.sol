pragma solidity >= 0.5.0;

import { DssDeployTestBase } from "dss-deploy/DssDeploy.t.base.sol";
import "./OasisCdpManager.sol";

contract FakeUser {
    function doFrob(
        OasisCdpManager manager,
        address usr,
        bytes32 ilk,
        int dink,
        int dart
    ) public {
        manager.frob(usr, ilk, dink, dart);
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
        manager.open("ETH");
        assertEq(vat.can(manager.urns(address(this), "ETH"), address(manager)), 1);
        address urn = manager.urns(address(this), "ETH");
        if (urn == address(0))
            fail();
    }

    function testOpenCDPOtherAddress() public {
        manager.open("ETH", address(123));
        address urn = manager.urns(address(123), "ETH");
        if (urn == address(0))
            fail();
    }

    function testFailOpenCDPZeroAddress() public {
        manager.open("ETH", address(0));
    }

    function testFailOpenOverride() public {
        manager.open("ETH", address(123));
        manager.open("ETH", address(123));
    }

    function testFrob() public {
        manager.open("ETH");
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), 1 ether);
        ethJoin.join(manager.urns(address(this), "ETH"), 1 ether);
        manager.frob(address(this), "ETH", 1 ether, 50 ether);
        assertEq(vat.dai(manager.urns(address(this), "ETH")), 50 ether * ONE);
        assertEq(vat.dai(address(this)), 0);
        manager.move(address(this), "ETH", address(this), 50 ether * ONE);
        assertEq(vat.dai(manager.urns(address(this), "ETH")), 0);
        assertEq(vat.dai(address(this)), 50 ether * ONE);
        assertEq(dai.balanceOf(address(this)), 0);
        vat.hope(address(daiJoin));
        daiJoin.exit(address(this), 50 ether);
        assertEq(dai.balanceOf(address(this)), 50 ether);
    }

    function testFrobDaiOtherDst() public {
        manager.open("ETH");
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), 1 ether);
        ethJoin.join(manager.urns(address(this), "ETH"), 1 ether);
        manager.frob(address(this), "ETH", address(this), 1 ether, 50 ether);
        assertEq(vat.dai(manager.urns(address(this), "ETH")), 0);
        assertEq(vat.dai(address(this)), 50 ether * ONE);
    }

    function testFrobGemOtherDst() public {
        manager.open("ETH");
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), 1 ether);
        ethJoin.join(manager.urns(address(this), "ETH"), 1 ether);
        manager.frob(address(this), "ETH", 1 ether, 50 ether);
        assertEq(vat.gem("ETH", manager.urns(address(this), "ETH")), 0);
        assertEq(vat.gem("ETH", address(this)), 0);
        manager.frob(address(this), "ETH", address(this), -int(1 ether), -int(50 ether));
        assertEq(vat.gem("ETH", manager.urns(address(this), "ETH")), 0);
        assertEq(vat.gem("ETH", address(this)), 1 ether);
    }

    function testFailFrobNotAllowed() public {
        manager.open("ETH");
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), 1 ether);
        ethJoin.join(manager.urns(address(this), "ETH"), 1 ether);
        user.doFrob(manager, address(this), "ETH", 1 ether, 50 ether);
    }

    function testFrobGetCollateralBack() public {
        manager.open("ETH");
        weth.deposit.value(1 ether)();
        weth.approve(address(ethJoin), 1 ether);
        ethJoin.join(manager.urns(address(this), "ETH"), 1 ether);
        manager.frob(address(this), "ETH", 1 ether, 50 ether);
        manager.frob(address(this), "ETH", -int(1 ether), -int(50 ether));
        assertEq(vat.dai(address(this)), 0);
        assertEq(vat.gem("ETH", manager.urns(address(this), "ETH")), 1 ether);
        assertEq(vat.gem("ETH", address(this)), 0);
        manager.flux(address(this), "ETH", address(this), 1 ether);
        assertEq(vat.gem("ETH", manager.urns(address(this), "ETH")), 0);
        assertEq(vat.gem("ETH", address(this)), 1 ether);
        uint prevBalance = address(this).balance;
        ethJoin.exit(address(this), 1 ether);
        weth.withdraw(1 ether);
        assertEq(address(this).balance, prevBalance + 1 ether);
    }

    function testGetWrongCollateralBack() public {
        manager.open("ETH");
        col.mint(1 ether);
        col.approve(address(colJoin), 1 ether);
        colJoin.join(manager.urns(address(this), "ETH"), 1 ether);
        assertEq(vat.gem("COL", manager.urns(address(this), "ETH")), 1 ether);
        assertEq(vat.gem("COL", address(this)), 0);
        manager.flux(address(this), "ETH", "COL", address(this), 1 ether);
        assertEq(vat.gem("COL", manager.urns(address(this), "ETH")), 0);
        assertEq(vat.gem("COL", address(this)), 1 ether);
    }

}
