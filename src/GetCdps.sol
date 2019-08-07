pragma solidity >= 0.5.0;

import "./OasisCdpManager.sol";

contract GetCdps {
    function getCdpsAsc(address manager, address guy) external view returns (uint[] memory ids, address[] memory urns, bytes32[] memory ilks) {
        uint count = OasisCdpManager(manager).count(guy);
        ids = new uint[](count);
        urns = new address[](count);
        ilks = new bytes32[](count);
        uint i = 0;
        uint id = OasisCdpManager(manager).first(guy);

        while (id > 0) {
            ids[i] = id;
            urns[i] = OasisCdpManager(manager).urns(id);
            ilks[i] = OasisCdpManager(manager).ilks(id);
            (,id) = OasisCdpManager(manager).list(id);
            i++;
        }
    }

    function getCdpsDesc(address manager, address guy) external view returns (uint[] memory ids, address[] memory urns, bytes32[] memory ilks) {
        uint count = OasisCdpManager(manager).count(guy);
        ids = new uint[](count);
        urns = new address[](count);
        ilks = new bytes32[](count);
        uint i = 0;
        uint id = OasisCdpManager(manager).last(guy);

        while (id > 0) {
            ids[i] = id;
            urns[i] = OasisCdpManager(manager).urns(id);
            ilks[i] = OasisCdpManager(manager).ilks(id);
            (id,) = OasisCdpManager(manager).list(id);
            i++;
        }
    }
}
