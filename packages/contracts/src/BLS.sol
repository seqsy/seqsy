// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

library BLS {
    /**
     * @notice same function as AddAssign in https://github.com/ConsenSys/gnark-crypto/blob/master/ecc/bn254/g2.go
     */

    uint256 internal constant MODULUS =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;

    uint256 internal constant G2x1 =
        11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 internal constant G2x0 =
        10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 internal constant G2y1 =
        4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 internal constant G2y0 =
        8495653923123431417604973247489272438418190587263600148770280649306958101930;

    function addJac(
        uint256[6] memory jac1,
        uint256[6] memory jac2
    ) internal pure returns (uint256[6] memory) {
        //NOTE: JAC IS REFERRED TO AS X, Y, Z
        //ALL 2 ELEMENTS EACH
        // var XX, YY, YYYY, ZZ, S, M, T fptower.E2

        if (jac1[4] == 0 && jac1[5] == 0) {
            // on point 1 being a point at infinity
            return jac2;
        } else if (jac2[4] == 0 && jac2[5] == 0) {
            // on point 2 being a point at infinity
            return jac1;
        }

        // var Z1Z1, Z2Z2, U1, U2, S1, S2, H, I, J, r, V fptower.E2
        //z1z1 = a.z^2
        uint256[4] memory z1z1z2z2;
        (z1z1z2z2[0], z1z1z2z2[1]) = square(jac2[4], jac2[5]);
        //z2z2 = p.z^2
        // uint256[2] memory z2z2;
        (z1z1z2z2[2], z1z1z2z2[3]) = square(jac1[4], jac1[5]);
        //u1 = a.x*z2z2
        uint256[4] memory u1u2;
        (u1u2[0], u1u2[1]) = mul(jac2[0], jac2[1], z1z1z2z2[2], z1z1z2z2[3]);
        //u2 = p.x*z1z1
        // uint256[2] memory u2;
        (u1u2[2], u1u2[3]) = mul(jac1[0], jac1[1], z1z1z2z2[0], z1z1z2z2[1]);
        //s1 = a.y*p.z*z2z2
        uint256[2] memory s1;
        (s1[0], s1[1]) = mul(jac2[2], jac2[3], jac1[4], jac1[5]);
        (s1[0], s1[1]) = mul(s1[0], s1[1], z1z1z2z2[2], z1z1z2z2[3]);

        //s2 = p.y*a.z*z1z1
        uint256[2] memory s2;
        (s2[0], s2[1]) = mul(jac1[2], jac1[3], jac2[4], jac2[5]);
        (s2[0], s2[1]) = mul(s2[0], s2[1], z1z1z2z2[0], z1z1z2z2[1]);

        // // if p == a, we double instead, is this too inefficient?
        // // if (u1[0] == 0 && u1[1] == 0 && u2[0] == 0 && u2[1] == 0) {
        // //     return p.DoubleAssign()
        // // } else {

        // // }

        uint256[2] memory h;
        uint256[2] memory i;

        assembly {
            //h = u2 - u1
            mstore(
                h,
                addmod(
                    mload(add(u1u2, 0x040)),
                    sub(MODULUS, mload(u1u2)),
                    MODULUS
                )
            )
            mstore(
                add(h, 0x20),
                addmod(
                    mload(add(u1u2, 0x60)),
                    sub(MODULUS, mload(add(u1u2, 0x20))),
                    MODULUS
                )
            )

            //i = 2h
            mstore(i, mulmod(mload(h), 2, MODULUS))
            mstore(add(i, 0x20), mulmod(mload(add(h, 0x20)), 2, MODULUS))
        }

        (i[0], i[1]) = square(i[0], i[1]);

        uint256[2] memory j;
        (j[0], j[1]) = mul(h[0], h[1], i[0], i[1]);

        uint256[2] memory r;
        assembly {
            //r = s2 - s1
            mstore(r, addmod(mload(s2), sub(MODULUS, mload(s1)), MODULUS))
            mstore(
                add(r, 0x20),
                addmod(
                    mload(add(s2, 0x20)),
                    sub(MODULUS, mload(add(s1, 0x20))),
                    MODULUS
                )
            )

            //r *= 2
            mstore(r, mulmod(mload(r), 2, MODULUS))
            mstore(add(r, 0x20), mulmod(mload(add(r, 0x20)), 2, MODULUS))
        }

        uint256[2] memory v;
        (v[0], v[1]) = mul(u1u2[0], u1u2[1], i[0], i[1]);

        (jac1[0], jac1[1]) = square(r[0], r[1]);

        assembly {
            //x -= j
            mstore(jac1, addmod(mload(jac1), sub(MODULUS, mload(j)), MODULUS))
            mstore(
                add(jac1, 0x20),
                addmod(
                    mload(add(jac1, 0x20)),
                    sub(MODULUS, mload(add(j, 0x20))),
                    MODULUS
                )
            )
            //x -= v
            mstore(jac1, addmod(mload(jac1), sub(MODULUS, mload(v)), MODULUS))
            mstore(
                add(jac1, 0x20),
                addmod(
                    mload(add(jac1, 0x20)),
                    sub(MODULUS, mload(add(v, 0x20))),
                    MODULUS
                )
            )
            //x -= v
            mstore(jac1, addmod(mload(jac1), sub(MODULUS, mload(v)), MODULUS))
            mstore(
                add(jac1, 0x20),
                addmod(
                    mload(add(jac1, 0x20)),
                    sub(MODULUS, mload(add(v, 0x20))),
                    MODULUS
                )
            )
            //y = v - x
            mstore(
                add(jac1, 0x40),
                addmod(mload(v), sub(MODULUS, mload(jac1)), MODULUS)
            )
            mstore(
                add(jac1, 0x60),
                addmod(
                    mload(add(v, 0x20)),
                    sub(MODULUS, mload(add(jac1, 0x20))),
                    MODULUS
                )
            )
        }

        (jac1[2], jac1[3]) = mul(jac1[2], jac1[3], r[0], r[1]);
        (s1[0], s1[1]) = mul(s1[0], s1[1], j[0], j[1]);

        assembly {
            //s1 *= 2
            mstore(s1, mulmod(mload(s1), 2, MODULUS))
            mstore(add(s1, 0x20), mulmod(mload(add(s1, 0x20)), 2, MODULUS))
            //y -= s1
            mstore(
                add(jac1, 0x40),
                addmod(mload(add(jac1, 0x40)), sub(MODULUS, mload(s1)), MODULUS)
            )
            mstore(
                add(jac1, 0x60),
                addmod(
                    mload(add(jac1, 0x60)),
                    sub(MODULUS, mload(add(s1, 0x20))),
                    MODULUS
                )
            )
            //z = a.z + p.z
            mstore(
                add(jac1, 0x80),
                addmod(mload(add(jac1, 0x80)), mload(add(jac2, 0x80)), MODULUS)
            )
            mstore(
                add(jac1, 0xA0),
                addmod(mload(add(jac1, 0xA0)), mload(add(jac2, 0xA0)), MODULUS)
            )
        }

        (jac1[4], jac1[5]) = square(jac1[4], jac1[5]);

        assembly {
            //z -= z1z1
            mstore(
                add(jac1, 0x80),
                addmod(
                    mload(add(jac1, 0x80)),
                    sub(MODULUS, mload(z1z1z2z2)),
                    MODULUS
                )
            )
            mstore(
                add(jac1, 0xA0),
                addmod(
                    mload(add(jac1, 0xA0)),
                    sub(MODULUS, mload(add(z1z1z2z2, 0x20))),
                    MODULUS
                )
            )
            //z -= z2z2
            mstore(
                add(jac1, 0x80),
                addmod(
                    mload(add(jac1, 0x80)),
                    sub(MODULUS, mload(add(z1z1z2z2, 0x40))),
                    MODULUS
                )
            )
            mstore(
                add(jac1, 0xA0),
                addmod(
                    mload(add(jac1, 0xA0)),
                    sub(MODULUS, mload(add(z1z1z2z2, 0x60))),
                    MODULUS
                )
            )
        }

        (jac1[4], jac1[5]) = mul(jac1[4], jac1[5], h[0], h[1]);

        return jac1;
    }

    function square(
        uint256 x0,
        uint256 x1
    ) internal pure returns (uint256, uint256) {
        uint256[4] memory z;
        assembly {
            //a = x0 + x1
            mstore(z, addmod(x0, x1, MODULUS))
            //b = x0 - x1
            mstore(add(z, 0x20), addmod(x0, sub(MODULUS, x1), MODULUS))
            //a = (x0 + x1)(x0 - x1)
            mstore(add(z, 0x40), mulmod(mload(z), mload(add(z, 0x20)), MODULUS))
            //b = 2x0y0
            mstore(add(z, 0x60), mulmod(2, mulmod(x0, x1, MODULUS), MODULUS))
        }
        return (z[2], z[3]);
    }

    function mul(
        uint256 x0,
        uint256 x1,
        uint256 y0,
        uint256 y1
    ) internal pure returns (uint256, uint256) {
        uint256[5] memory z;
        assembly {
            //a = x0 + x1
            mstore(z, addmod(x0, x1, MODULUS))
            //b = y0 + y1
            mstore(add(z, 0x20), addmod(y0, y1, MODULUS))
            //a = (x0 + x1)(y0 + y1)
            mstore(z, mulmod(mload(z), mload(add(z, 0x20)), MODULUS))
            //b = x0y0
            mstore(add(z, 0x20), mulmod(x0, y0, MODULUS))
            //c = x1y1
            mstore(add(z, 0x40), mulmod(x1, y1, MODULUS))
            //c = -x1y1
            mstore(add(z, 0x40), sub(MODULUS, mload(add(z, 0x40))))
            //z0 = x0y0 - x1y1
            mstore(
                add(z, 0x60),
                addmod(mload(add(z, 0x20)), mload(add(z, 0x40)), MODULUS)
            )
            //b = -x0y0
            mstore(add(z, 0x20), sub(MODULUS, mload(add(z, 0x20))))
            //z1 = x0y1 + x1y0
            mstore(
                add(z, 0x80),
                addmod(
                    addmod(mload(z), mload(add(z, 0x20)), MODULUS),
                    mload(add(z, 0x40)),
                    MODULUS
                )
            )
        }
        return (z[3], z[4]);
    }
}
