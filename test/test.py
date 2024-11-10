# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    # Set the input values you want to test
    dut.ui_in.value = 0
    dut.uio_in.value = 128 # bypass B
    # makes chirp
    for i in range(127):
        dut.ui_in.value = i % 128
        await ClockCycles(dut.clk, 4)

    dut.uio_in.value = 128 + 64 # bypass B + lowamp
    for i in range(127):
        dut.ui_in.value = i % 128
        await ClockCycles(dut.clk, 4)

    # set A to ~10 MHz
    dut.ui_in.value = 51
    # set B to ~1 MHz
    dut.uio_in.value = 5
    await ClockCycles(dut.clk, 500)

    # turn on filter
    dut.ui_in.value = 51 + 128
    await ClockCycles(dut.clk, 500)

    # MANUALLY VERIFY WAVEFORMS

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    #assert dut.uo_out.value == 30

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
