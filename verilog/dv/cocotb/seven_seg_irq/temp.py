import tkinter as tk

def submit_text():
    user_text = entry.get()  # Get the text entered by the user
    canvas.create_text(100, 100, text=user_text, fill='black', font='Arial 20')

# Create the main window
window = tk.Tk()

# Create a canvas
canvas = tk.Canvas(window, width=400, height=300)
canvas.pack()

# Create an entry widget for the user to input text
entry = tk.Entry(window)
entry.pack()

# Create a button to submit the text
submit_button = tk.Button(window, text='Submit', command=submit_text)
submit_button.pack()

# Start the main event loop
window.mainloop()
