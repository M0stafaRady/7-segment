from caravel_cocotb.caravel_interfaces import report_test
import cocotb
from caravel_cocotb.caravel_interfaces import test_configure
from cocotb.triggers import ClockCycles, Edge, First, NextTimeStep
import tkinter as tk
import time

realistic_gui = False


@cocotb.test()
# use report_test for configuring the logs correctly
@report_test
async def seven_seg_init_val(dut):
    # configure file used for configuring caravel power, clock, and reset and setup the timeout watchdog then return object of caravel environment.
    caravelEnv = await test_configure(dut, timeout_cycles=275837)
    # logic for setup the gui 
    digit0 = digit1 = digit2 = digit3 = 0xFE
    root = tk.Tk()
    root.title("7 segment display")
    screen = tk.Canvas(root, width=1500, height=500)
    screen.grid()
    dig3 = Digit(screen, 110, 110) 
    dig2 = Digit(screen, 360, 110) 
    TwoDots(screen, 610, 110, 710, 210) 
    TwoDots(screen, 610, 310, 710, 410)
    dig1 = Digit(screen, 804, 110)
    dig0 = Digit(screen, 1054, 110)
    dig0.show(int_to_seg(digit0))
    dig1.show(int_to_seg(digit0))
    dig2.show(int_to_seg(digit0))
    dig3.show(int_to_seg(digit0))
    root.update()
    await caravelEnv.wait_mgmt_gpio(1)
    while True:
        # detecting and reading the digit if any changes happened at the digit_en pins
        digit_num, digit = await read_seg(caravelEnv)
        # assigning the digit to the display
        if digit_num == 0:
            digit0 = digit
            dig0.show(int_to_seg(digit0))
        elif digit_num == 1:
            digit1 = digit
            dig1.show(int_to_seg(digit1))
        elif digit_num == 2:
            digit2 = digit
            dig2.show(int_to_seg(digit2))
        elif digit_num == 3:
            digit3 = digit
            dig3.show(int_to_seg(digit3))
        cocotb.log.debug(f"[Test] clock =  {int_to_seg(digit0)} {int_to_seg(digit1)} {int_to_seg(digit2)} {int_to_seg(digit3)}")
        # updating the display
        root.update()


async def read_seg(caravelEnv):
    # wait for any change at digit_en
    digit0 = Edge(caravelEnv.dut.gpio26_monitor)
    digit1 = Edge(caravelEnv.dut.gpio27_monitor)
    digit2 = Edge(caravelEnv.dut.gpio28_monitor)
    digit3 = Edge(caravelEnv.dut.gpio29_monitor)
    await First(digit0, digit1, digit2, digit3) # triggered with the first edge triggered
    await NextTimeStep()  # wait for 1 step to make sure the digit is updated as well
    digit_en = caravelEnv.monitor_gpio(29, 26).integer  # read digit_en pins 
    digit = caravelEnv.monitor_gpio(37, 30).integer  # read digit pins 
    cocotb.log.debug(f"digit_en = {hex(digit_en)} digit = {hex(digit)}")
    # decode the digit_en value to get the digit number
    if (digit_en == 0xE):
        digit_num = 0
    elif (digit_en == 0xD):
        digit_num = 1
    elif (digit_en == 0xB):
        digit_num = 2
    elif (digit_en == 0x7):
        digit_num = 3
    else:
        cocotb.log.error(f"[Test][read_seg] Invalid digit_en: {digit_en}")
    return digit_num, digit


def int_to_seg(digit):
    return {
        0xFE: 0,
        0xB0: 1,
        0xED: 2,
        0xF9: 3,
        0xB3: 4,
        0xDB: 5,
        0xDF: 6,
        0xF0: 7,
        0xFF: 8,
        0xFB: 9,
    }[digit]


class Digit:
    def __init__(self, canvas, x=10, y=10, length=160, width=32, is_2_dots=False):
        self.canvas = canvas
        l = length
        self.segs = []
        offsets = (
            (0, 0, 1, 0),  # top
            (1, 0, 1, 1),  # upper right
            (1, 1, 1, 2),  # lower right
            (0, 2, 1, 2),  # bottom
            (0, 1, 0, 2),  # lower left
            (0, 0, 0, 1),  # upper left
            (0, 1, 1, 1),  # middle
        )
        self.digits = (
            (1, 1, 1, 1, 1, 1, 0),  # 0
            (0, 1, 1, 0, 0, 0, 0),  # 1
            (1, 1, 0, 1, 1, 0, 1),  # 2
            (1, 1, 1, 1, 0, 0, 1),  # 3
            (0, 1, 1, 0, 0, 1, 1),  # 4
            (1, 0, 1, 1, 0, 1, 1),  # 5
            (1, 0, 1, 1, 1, 1, 1),  # 6
            (1, 1, 1, 0, 0, 0, 0),  # 7
            (1, 1, 1, 1, 1, 1, 1),  # 8
            (1, 1, 1, 1, 0, 1, 1),  # 9
            (0, 0, 0, 0, 0, 0, 0),  # disable
        )
        for x0, y0, x1, y1 in offsets:
            self.segs.append(canvas.create_line(
                x + x0*l, y + y0*l, x + x1*l, y + y1*l,
                width=width, state='normal'))

    def show(self, num):
        for iid, on in zip(self.segs, self.digits[num]):
            self.canvas.itemconfigure(iid, fill='#B90E0A' if on else "")

class TwoDots:
    def __init__(self, canvas, x=10, y=10, length=20, width=4):
        self.canvas = canvas
        l = length
        canvas.create_oval(x, y, length, width, outline="#B90E0A" , fill="#B90E0A")