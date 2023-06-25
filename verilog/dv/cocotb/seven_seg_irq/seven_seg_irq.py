from caravel_cocotb.caravel_interfaces import report_test
import cocotb
from caravel_cocotb.caravel_interfaces import test_configure
from gui_screen import GuiScreen
from segments_monitor import SegmentsMonitor

@cocotb.test()
# use report_test for configuring the logs correctly
@report_test
async def seven_seg_irq(dut):
    # initialize the display gui before powering caravel on
    screen = GuiScreen()
    # configure file used for configuring caravel power, clock, and reset and setup the timeout watchdog then return object of caravel environment.
    caravelEnv = await test_configure(dut, timeout_cycles=417488)
    # fork that monitor the segments at the display
    await cocotb.start(show_time(caravelEnv, screen))
    # wait for the 2 alarms expected
    await detect_irq(caravelEnv)


async def show_time(caravelEnv, screen):
    segements_monitor = SegmentsMonitor(caravelEnv)
    while True:
        # detecting and reading the digit if any changes happened at the digit_en pins
        digit_num, digit = await segements_monitor.segment_change()
        # assigning the digit to the display
        screen.update_digit(digit_num, digit)


async def detect_irq(caravelEnv):
    await caravelEnv.wait_mgmt_gpio(1)
    cocotb.log.info("[TEST] Seen alarm interrupt at 1:45")
    await caravelEnv.wait_mgmt_gpio(0)
    cocotb.log.info("[TEST] Clear alarm interrupt and wait for new interrupt at 3:00")
    await caravelEnv.wait_mgmt_gpio(1)
    cocotb.log.info("[TEST] Seen alarm interrupt at 3:00")