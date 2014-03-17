#!/usr/bin/env python3
"""
SYNOPSIS

    translate_multipatch_info.py [-h,--help] [-v,--verbose] [--version]

DESCRIPTION

    This script translates a .txt input file with information useful
    to specify a 'multipatch', i.e. contains the information on the 
    geometric decomposition of a 2D domain into multiple regions or 'patches'
    each of which is in turn described by a separate file which specifies its
    geometry based on Non-uniform Rational B-Splines (NURBS). This particular
    script deals with the translation of the file which contains the relations
    between the patches, how many, which faces are connected, etc. The output
    file is a namelist file readable by the Selalib library.
    The original file should have contents formatted as:

# Rd
3
# dim
2
# npatchs
5
# external_faces
0, 2
1, 2
2, 2
3, 2
# internal_faces
0, 0
0, 1
0, 3
1, 0
1, 1
1, 3
2, 0
2, 1
2, 3
3, 0
3, 1
3, 3
4, 0
4, 1
4, 2
4, 3
# connectivity
clone
1, 3
original
0, 1
clone
3, 1
original
2, 3
clone
3, 3
original
0, 3
clone
2, 1
original
1, 1
clone
4, 3
original
0, 0
clone
4, 0
original
1, 0
clone
4, 1
original
2, 0
clone
4, 2
original
3, 0

EXAMPLES

    ./translate_multipatch_info.py input_file.txt

EXIT STATUS

    TODO:

AUTHOR

    Edwin CHACON-GOLCHER <golcher@math.unistra.fr>

LICENSE

    Same as Selalib's...

VERSION

    1.0
"""

import sys, os, traceback, optparse
import time
import re
import pprint

sys.stdout = open('translate_multipatch_info.out', 'w')
#from pexpect import run, spawn

def main ():

    global options, args
    inputname      = "" # empty filename at the start
    inputfilename  = "" # name of the read-only file (could differ from input)
    readfilename   = ""
    currently_reading = ""
    currently_reading_sub = ""
    label = ""
    under_pos = 0
    name_root = ""
    num_slots = 0
    patch = 0
    face = 0
    opatch = 0 # other patch
    oface = 0  # other face
    flattened = []
    tokens = []
    pp = pprint.PrettyPrinter(indent=4)
    # patch numbering starts at 0, so is the numbering of the faces.
    connectivities = [] # single array, size number_patchesX8
    print('number of arguments passed')
    print(len(args))
    # in case that no arguments were provided, request a filename from the user
    if (len(args) == 0):
        print( "Enter the name of the file to convert to namelist format:")
        while 1:
            next = sys.stdin.read(1)
            if next == "\n":
                break
            inputname += next
    elif (len(args) > 1): # 2 or more arguments given
        print( "Please enter one argument only. Usage: ")
        print( "user$ ./translate_multipatch_info.py filename.txt")
        sys.exit()
    else:                   # exactly one argument given
       # inputname = process_file_name(args[0])
        tokens = args[0].split('/')
        inputname = tokens[len(tokens)-1]
    # check whether the user has given the .txt extension or not, and create 
    # the name of the output file. Echo to screen the names of the files to be
    # read and written.
    numdots = inputname.count('.')
    if numdots == 0: # no extension, thus just add the extension to files
        outputname   = inputname + ".nml"   # output file name
        readfilename = inputname + ".txt" 
    elif numdots == 1: # there is an extension
        dotposition  = inputname.find('.')
        #   print inputname[dotposition:]
        if inputname[dotposition:] == ".txt": # it has the right extension
            readfilename = inputname           # open file with name as given
            outputname   = inputname[:dotposition] + ".nml" # create output name
        else:
            print( "Wrong extension. Only .txt files are allowed.")
            sys.exit()
    else:
        print( "That is a very weird-looking filename!")
        outputname   = inputname + ".nml"   # just add the extension
        readfilename = inputname + ".txt"  

    print( "The file to be processed is: {0} ".format(readfilename))
    print( "Converting {0} to {1}".format(readfilename, outputname))

    with open(readfilename,'r') as readfile, open(outputname,'w') as writefile:
        now  = time.localtime()
        date = str(now[1]) + "/" + str(now[2]) + "/" + str(now[0])
        mytime = str(now[3]) + ":" + str(now[4]) + ":" + str(now[5]) + "\n"
        writefile.write("! Input namelist file intended to initialize a ")
        writefile.write("2D geometry described by \n")
        writefile.write("! multiple coordinate transformations, ")
        writefile.write("i.e. a multipatch.\n")
#        writefile.write("! This should be done with a call like: \n\n")
#        writefile.write("!       call T%initialize_from_file(filename)\n\n")
        writefile.write("! Generated by "+sys.argv[0]+"\n")
        writefile.write("! on: " + date + "," + mytime)
        writefile.write("! Original input file: "+"\n"+"! "+readfilename +"\n\n\n")
        # The multipatch file contains a label for possible use, here we choose
        # the name of the file as the label.
        writefile.write("&multipatch_label\n")
        dotposition = outputname.find('.')
        label = outputname[:dotposition]
        writefile.write("    label = "+"\"" + label + "\""+"\n")
        writefile.write("/" + "\n\n")
        
        # The multipatch produced by Pigasus/Caid is a collection of files
        # composed of an X_info.txt file and multiple X_patchY.txt files. X
        # is the root of the name (shared by all files) and Y is the patch
        # index (0.. num_patches-1).

        under_pos = label.rfind('_')
        name_root = label[:under_pos+1]
        print(name_root)

        linelist = readfile.readlines()

        for line in linelist:
            linetemp = line.split() # split in constituent tokens
            if len(linetemp) > 0:
                if currently_reading == "":   # seeking which slot to fill
                    if linetemp[0] == "#":
                        if linetemp[1] == "Rd":  
                            num_slots += 1           # add 1 to slot count
                            currently_reading = "Rd"
                            writefile.write("&rd\n")
                            continue
                        elif linetemp[1] == "dim":
                            num_slots += 1           # add 1 to slot count
                            currently_reading = "dim"
                            writefile.write("&dim\n")
                            continue
                        elif linetemp[1] == "npatchs":
                            num_slots += 1           # add 1 to slot count
                            currently_reading = "npatchs"
                            writefile.write("&num_patches\n")
                            continue
                        elif linetemp[1] == "external_faces":
                            num_slots += 1 
                            currently_reading = "external_faces"
                            # writefile.write("&external_faces\n")
                            continue
                        elif linetemp[1] == "internal_faces":
                            num_slots += 1
                            currently_reading = "internal_faces"
                            # writefile.write("&internal_faces\n")
                            continue
                        elif linetemp[1] == "connectivity":
                            num_slots += 1
                            currently_reading = "connectivity"
                            writefile.write("! The connectivities array in ")
                            writefile.write("this file is an array ")
                            writefile.write("of dimensions \n! number_patches ")
                            writefile.write("X 8. The i-th row ")
                            writefile.write("contains the connectivity ")
                            writefile.write("information for \n")
                            writefile.write("! the i-th ")
                            writefile.write("face. The connectivity of each ")
                            writefile.write("face is described by ")
                            writefile.write("a pair. The \n! first value is ")
                            writefile.write("the other patch and ")
                            writefile.write("the second is the connecting ")
                            writefile.write("face in \n")
                            writefile.write("! such patch. The ")
                            writefile.write("reader of this function should ")
                            writefile.write("properly dimension ")
                            writefile.write("the \n! receiving array and ")
                            writefile.write("transpose, given the ")
                            writefile.write("column-")
                            writefile.write("major convention used by \n! ")
                            writefile.write("Fortran.\n\n")
                            writefile.write("&connectivity\n")
                            continue
                        else:
                            print('It seems there is an input file problem: ')
                            print('untagged data present?')
                elif currently_reading == "Rd":
                    writefile.write("    whatisthisrd = "+linetemp[0]+"\n")
                    writefile.write("/" + "\n\n")
                    currently_reading = ""
                    continue
                elif currently_reading == "dim":
                    writefile.write("    dimension = " + linetemp[0] + "\n")
                    writefile.write("/" + "\n\n")
                    currently_reading = ""
                    continue
                elif currently_reading == "npatchs":
                    num_patches = int(linetemp[0])
                    writefile.write("    number_patches  = "+linetemp[0]+"\n")
                    writefile.write("/" + "\n\n")
                    currently_reading = ""
                    connectivities = [[ -1 for j in range(8)] 
                                      for i in range(int(linetemp[0])) ]
                    print( connectivities )
                    continue
                elif currently_reading == "external_faces":
                    currently_reading = ""
                    continue
                elif currently_reading == "internal_faces":
                    currently_reading = ""
                    continue
                elif currently_reading == "connectivity":
                    # We store the connectivity information in a 2D
                    # array. Each row of the array represents the 
                    # connectivity information for a patch. There are
                    # 8 columns in the array, such that for each face
                    # (0..3) there is a corresponding pair which says
                    # which patch and which face are connected. If a pair
                    # of fields is filled, this implies that there is a 
                    # connection between two faces, else the code for an
                    # external face is (-1,-1), that is, external faces are
                    # "connected" to the face -1 of the patch -1, which 
                    # should not represent any real patch.
                    if currently_reading_sub == "":
                        if linetemp[0] == "clone":
                            currently_reading_sub = "clone"
                            continue
                        elif linetemp[0] == "original":
                            currently_reading_sub = "original"
                            continue
                    elif currently_reading_sub == "clone":
                        comma_position = linetemp[0].find(',')
                        tmp = linetemp[0][:comma_position]
                        patch = int(linetemp[0][:comma_position])
                        face  = int(linetemp[1])
                        currently_reading_sub = ""
                        continue
                    elif currently_reading_sub == "original":
                        comma_position = linetemp[0].find(',')
                        opatch = int(linetemp[0][:comma_position])
                        oface  = int(linetemp[1])
                        connectivities[patch][face*2]     = opatch
                        connectivities[patch][face*2+1]   = oface
                        connectivities[opatch][oface*2]   = patch
                        connectivities[opatch][oface*2+1] = face
                        currently_reading_sub = ""
                        continue
        flattened = [item for sublist in connectivities for item in sublist]

        writefile.write("    connectivities = " + 
                        " ".join([str(item) for item in  flattened]) + "\n")
        writefile.write("/" + "\n\n")

        writefile.write("&patch_names\n")
        writefile.write("    patches = " + 
                        " ".join( "\"" + name_root + "patch" + str(i) + 
                                  ".nml\"" for i in range(num_patches)) + "\n" )
        writefile.write("/"+ "\n\n")


if __name__ == '__main__':
    try:
        start_time = time.time()
        parser = optparse.OptionParser(formatter=optparse.TitledHelpFormatter(), usage=globals()['__doc__'], version='1.0')
        parser.add_option ('-v', '--verbose', action='store_true', default=False, help='verbose output')
        (options, args) = parser.parse_args()
        #if len(args) < 1:
        #    parser.error ('missing argument')
        if options.verbose: print( time.asctime())
        main()
        if options.verbose: print(* time.asctime())
        if options.verbose: print( 'execution time in seconds:')
        if options.verbose: print( (time.time() - start_time))
        sys.exit(0)
    except KeyboardInterrupt as e: # Ctrl-C
        raise e
    except SystemExit as e: # sys.exit()
        raise e
    except Exception as e:
        print( 'ERROR, UNEXPECTED EXCEPTION')
        print( str(e))
        traceback.print_exc()
        os._exit(1)


