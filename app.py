import tkinter as tk
import csv
import os
import webbrowser

def load_data_from_csv(filename):
    data = {}
    if not os.path.exists(filename):
        return data
    with open(filename, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            data[row['Name']] = [row['Email'], row['Contact']]
    return data

contact_data = load_data_from_csv('contacts.csv')

def update_list(data_keys):
    listbox.delete(0, tk.END)
    for name in data_keys:
        listbox.insert(tk.END, name)

def check_input(event):
    typed = search_entry.get()
    if typed == '':
        listbox.pack_forget()
        update_list([])
    else:
        filtered_names = [name for name in contact_data.keys() if typed.lower() in name.lower()]
        if filtered_names:
            listbox.pack(pady=5, padx=20, fill="both", expand=True, before=result_frame)
            update_list(filtered_names)
        else:
            listbox.pack_forget()

def show_details(event):
    try:
        index = listbox.curselection()[0]
        selected_name = listbox.get(index)
        details = contact_data[selected_name]
        
        res_name.config(text=f"Full Name: {selected_name}")
        res_email.config(text=f"{details[0]}", fg="blue", cursor="hand2")
        res_contact.config(text=f"Contact: {details[1]}")
        copy_btn.pack(side="left", padx=10) # Show copy button when data exists
    except IndexError:
        pass

def send_email(event):
    email_address = res_email.cget("text")
    if "@" in email_address:
        webbrowser.open(f"mailto:{email_address}")

def copy_email():
    email_address = res_email.cget("text")
    if email_address:
        root.clipboard_clear()
        root.clipboard_append(email_address)
        # Visual feedback
        copy_btn.config(text="Copied!", fg="green")
        root.after(1000, lambda: copy_btn.config(text="Copy", fg="black"))

def clear_all():
    search_entry.delete(0, tk.END)
    listbox.pack_forget()
    res_name.config(text="Full Name: ")
    res_email.config(text="", fg="black")
    res_contact.config(text="Contact: ")
    copy_btn.pack_forget()

# GUI Setup
root = tk.Tk()
root.title("E&M Contact Finder")
root.geometry("400x600")

# Search Area
search_frame = tk.Frame(root)
search_frame.pack(pady=10, padx=20, fill="x")

tk.Label(search_frame, text="Type a name to search:", font=("Arial", 10)).pack(anchor="w")
search_entry = tk.Entry(search_frame, font=("Arial", 12))
search_entry.pack(pady=5, fill="x", side="left", expand=True)
search_entry.bind("<KeyRelease>", check_input)

clear_btn = tk.Button(search_frame, text="Clear", command=clear_all)
clear_btn.pack(side="right", padx=5)

# Suggestion Listbox
listbox = tk.Listbox(root, font=("Arial", 10))
listbox.bind("<<ListboxSelect>>", show_details)

# Results Display Area
result_frame = tk.LabelFrame(root, text="Contact Information", padx=10, pady=10)
result_frame.pack(pady=20, padx=20, fill="x", side="bottom")

res_name = tk.Label(result_frame, text="Full Name: ", font=("Arial", 10, "bold"), anchor="w")
res_name.pack(fill="x")

# Email row with Copy Button
email_row = tk.Frame(result_frame)
email_row.pack(fill="x", pady=5)
tk.Label(email_row, text="Email: ", anchor="w").pack(side="left")
res_email = tk.Label(email_row, text="", anchor="w", font=("Arial", 10, "underline"))
res_email.pack(side="left")
res_email.bind("<Button-1>", send_email)

copy_btn = tk.Button(email_row, text="Copy", font=("Arial", 8), command=copy_email)
# Hidden initially via show_details logic

res_contact = tk.Label(result_frame, text="Contact: ", anchor="w")
res_contact.pack(fill="x")

root.mainloop()