version 1.1

struct Biofile {
    File file
    File? index
}

struct fastagz {
    Biofile fa
    File? index
}

struct Genome {
    Biofile fa
    fastagz? gz
    File? dict
    File? amb
    File? ann
    File? bwt
    File? pac
    File? sa
}

struct Fastq {
    File R1
    File? R2
}