"""Test module 2"""
import sys
from test_module3 import helper_function

def some_function():
    print("Module 2")
    helper_function()

def another_function():
    return "Hello from module 2"
