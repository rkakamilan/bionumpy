import bionumpy as bnp
import dataclasses

rule bionumpy_reverse_complement:
    # todo: Not giving correct results now
    input:
        "results/dna_sequences/{filename}.fa"
    output:
        "results/bionumpy/reverse_complement/{filename}.fa"
    benchmark:
        "benchmarks/reverse_complement/bionumpy/{filename}.txt"
    run:
        file = bnp.open(input[0])
        outfile = bnp.open(output[0], "w")
        for chunk in file:
            sequence = bnp.change_encoding(chunk.sequence, bnp.DNAEncoding)
            reverse_complement = bnp.sequence.get_reverse_complement(sequence)
            # ?
            reverse_complement = bnp.change_encoding(reverse_complement, bnp.DNAEncoding)
            dataclasses.replace(chunk, sequence=reverse_complement)
            outfile.write(chunk)

        outfile.close()



rule seqtk_reverse_complement:
    input:
        "results/dna_sequences/{filename}.fa"
    output:
        "results/seqtk/reverse_complement/{filename}.fa"
    log:
        "results/seqtk/reverse_complement/{filename}.log"
    params:
        extra="-r",
    benchmark:
        "benchmarks/reverse_complement/seqtk/{filename}.txt"
    wrapper:
        "v1.19.2/bio/seqtk/seq"


rule biopython_reverse_complement:
    input:
        "results/dna_sequences/{filename}.fa"
    output:
        "results/biopython/reverse_complement/{filename}.fa"
    benchmark:
        "benchmarks/reverse_complement/biopython/{filename}.txt"
    run:
        from Bio import SeqIO
        from Bio.SeqRecord import SeqRecord

        with open(output[0],'w') as aa_fa:
            for dna_record in SeqIO.parse(input[0],'fasta'):
                new_record = SeqRecord(
                    dna_record.seq.reverse_complement(),
                    id=dna_record.id)
                SeqIO.write(new_record,aa_fa,'fasta')

rule python_reverse_complement:
    input:
        "results/dna_sequences/{filename}.fa"
    output:
        "results/python/reverse_complement/{filename}.fa"
    benchmark:
        "benchmarks/reverse_complement/python/{filename}.txt"
    run:
        def reverse_complement(sequence):
            mapping = {"A": "T", "T": "A", "C": "G", "G": "C",
                       "a": "t", "t": "a", "c": "g", "g": "c"}
            reverse = sequence[::-1]
            complement = "".join(mapping[b] for b in reverse)
            return complement

        with open(input[0]) as infile:
            with open(output[0], "w") as outfile:
                for line in infile:
                    if line.startswith(">"):
                        outfile.write(line)
                    else:
                        outfile.write(reverse_complement(line.strip()) + "\n")

