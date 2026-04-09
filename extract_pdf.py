import fitz
import sys

pdf_path = r"C:\Users\david\french_model\wp736.pdf"
doc = fitz.open(pdf_path)

print(f"Total pages: {len(doc)}")
print("=" * 80)

# Extract pages around section 3.1.1 (likely pages 8-20)
for i in range(len(doc)):
    page = doc[i]
    text = page.get_text()
    if "3.1" in text or "E-SAT" in text or "VAR" in text or "expectation" in text.lower():
        print(f"\n{'='*40} PAGE {i+1} {'='*40}")
        print(text)

doc.close()
