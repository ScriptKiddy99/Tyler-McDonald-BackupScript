Reqs:

Hey Conner. I've got one. On vacation so. No code at the moment. I have the bulk of the project and functionally working. One thing I'm looking for is to compare file size before completely a move.
I first copy file from source to local PC. Then I need to validate my local PC file sizes equals the original source file. If true, then I want to backup/move the original source file to a backup location before I work with it on my local PC.

Solution 01:

 generating a checksum for each of your files, then only copying over the files where the checksum has not been changed. This way even if one character in the file is removed and placed with something else the hash will be different, making it easier to spot edits than just comparing file size
