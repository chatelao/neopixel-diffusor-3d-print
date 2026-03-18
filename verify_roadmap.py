import re

def count_steps(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Match lines starting with a number followed by a dot
    steps = re.findall(r'^\d+\.\s+', content, re.MULTILINE)
    return len(steps)

if __name__ == "__main__":
    count = count_steps('ROADMAP.md')
    print(f"Number of steps found: {count}")
    if count == 30:
        print("Success: Roadmap contains exactly 30 steps.")
    else:
        print(f"Error: Expected 30 steps, found {count}.")
