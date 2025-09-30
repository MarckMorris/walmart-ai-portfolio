import sys, os
# añade la carpeta del proyecto (un nivel arriba de /tests) al sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
