version 1.0

# MobiDL 2.0 - MobiDL 2 is a collection of tools wrapped in WDL to be used in any WDL pipelines.
# Copyright (C) 2021 MoBiDiC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

task get_version {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2021-03-19"
	}

	input {
		String path_exe = "minimap2"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	command <<<
		~{path_exe} --version
	>>>

	output {
		String version = read_string(stdout())
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "bcftools"]',
			category: 'System'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memory: {
			description: 'Sets the total memory to use ; with suffix M/G [default: (memoryByThreads*threads)M]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}

task mapOnt {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.0.1"
		date: "2021-03-19"
	}

	input {
		String path_exe = "minimap2"
		String path_exe_samtools = "samtools"

		String? outputPath
		String? sample
		String subString = ".(fastq|fq)(.gz)?"
		String subStringReplace = ""

		File fastq

		File refFasta

		Boolean homopolymerCompressed = false
		Int KmerSize = 15
		Int minWindowSize = 10
		String splitIndex = "4G"
		File? dumpIndexFile

		Float filterOutFracMin = 0.0002
		Int stopChain = 5000
		Int minMinimizerChain = 3
		Int minChainScore = 40
		Float minSec2Prim = 0.8
		Int retainSec = 5

		Int matchingScore = 2
		Int mismatchPenalty = 4
		Int gapPenalty1 = 4
		Int gapPenalty2 = 24
		Int gapExtension1 = 2
		Int gapExtension2 = 1
		Int ZDropScore1 = 400
		Int ZDropScore2 = 200
		Int minPeakDP = 80
		String finGTAG = "n"

		Boolean SAMoutput = true
		Boolean writeCIGARSup65535 = false
		String platformReads = "ONT"
		Boolean? csShort
		Boolean MDtag = false
		Boolean CIGAROperator = false
		Boolean useSoftClipping = false
		Int miniBatch = 500000000

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(sample) then sample else sub(basename(fastq),subString,subStringReplace)
	String outputFile = if defined(outputPath) then "~{outputPath}/~{baseName}.bam" else "~{baseName}.bam"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} -x map-ont \
			~{true="-H" false="" homopolymerCompressed} \
			-k ~{KmerSize} \
			-w ~{minWindowSize} \
			-I ~{splitIndex} \
			~{default="" "-d " + dumpIndexFile} \
			-f ~{filterOutFracMin} \
			-g ~{stopChain} \
			-n ~{minMinimizerChain} \
			-m ~{minChainScore} \
			-p ~{minSec2Prim} \
			-N ~{retainSec} \
			-A ~{matchingScore} \
			-B ~{mismatchPenalty} \
			-O ~{gapPenalty1},~{gapPenalty2} \
			-E ~{gapExtension1},~{gapExtension2} \
			-z ~{ZDropScore1},~{ZDropScore2} \
			-s ~{minPeakDP} \
			-u ~{finGTAG} \
			~{true="-a" false="" SAMoutput} \
			~{true="-L" false="" writeCIGARSup65535} \
			-R "@RG\tID:~{baseName}\tSM:~{baseName}\tPL:~{platformReads}" \
			~{default="" true="--cs=short" false="--cs=long" csShort} \
			~{true="--MD" false="" MDtag} \
			~{true="--eqx" false="" CIGAROperator} \
			~{true="-Y" false="" useSoftClipping} \
			-K ~{miniBatch} \
			-t ~{threads} ~{refFasta} ~{fastq} | ~{path_exe_samtools} sort -@ ~{threads-1} -m ~{memoryByThreadsMb}M -o ~{outputFile}

	>>>

	output {
		File outputFile = outputFile
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "minimap2"]',
			category: 'System'
		}
		path_exe_samtools: {
			description: 'Path used as executable [default: "samtools"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where bam file was generated. [default: pwd()]',
			category: 'Output path/name option'
		}
		sample: {
			description: 'Sample name to use for output file name [default: sub(basename(fastq),subString,subStringReplace)]',
			category: 'Output path/name option'
		}
		subString: {
			description: 'Substring to remove to get sample name [default: ".(fastq|fq)(.gz)?"]',
			category: 'Output path/name option'
		}
		subStringReplace: {
			description: 'subString replace by this string [default: ""]',
			category: 'Output path/name option'
		}
		fastq: {
			description: 'Input file with reads (fastq, fastq.gz, fq, fq.gz).',
			category: 'Required'
		}
		refFasta: {
			description: 'Path to the reference file (format: fasta)',
			category: 'Required'
		}
		homopolymerCompressed: {
			description: 'use homopolymer-compressed k-mer (preferrable for PacBio)',
			category: 'Indexing'
		}
		KmerSize: {
			description: 'k-mer size (no larger than 28) [default: 15]',
			category: 'Indexing'
		}
		minWindowSize: {
			description: 'minimizer window size [default: 10]',
			category: 'Indexing'
		}
		splitIndex: {
			description: 'split index for every ~NUM input bases [default: 4G]',
			category: 'Indexing'
		}
		dumpIndexFile: {
			description: 'dump index to FILE',
			category: 'Indexing'
		}
		filterOutFracMin: {
			description: 'filter out top FLOAT fraction of repetitive minimizers [default: 0.0002]',
			category: 'Mapping'
		}
		stopChain: {
			description: 'stop chain enlongation if there are no minimizers in INT-bp [default: 5000]',
			category: 'Mapping'
		}
		minMinimizerChain: {
			description: 'minimal number of minimizers on a chain [default: 3]',
			category: 'Mapping'
		}
		minChainScore: {
			description: 'minimal chaining score (matching bases minus log gap penalty) [default: 40]',
			category: 'Mapping'
		}
		minSec2Prim: {
			description: 'min secondary-to-primary score ratio [default: 0.8]',
			category: 'Mapping'
		}
		retainSec: {
			description: 'retain at most INT secondary alignments [default: 5]',
			category: 'Mapping'
		}
		matchingScore: {
			description: 'matching score [default : 2]',
			category: 'Alignment'
		}
		mismatchPenalty: {
			description: 'mismatch penalty [default : 4]',
			category: 'Alignment'
		}
		gapPenalty1: {
			description: 'gap open penalty 1 [default : 4]',
			category: 'Alignment'
		}
		gapPenalty2: {
			description: 'gap open penalty 2 [default : 24]',
			category: 'Alignment'
		}
		gapExtension1: {
			description: 'gap extension penalty; a k-long gap costs min{O1+k*E1,O2+k*E2} 1 [default : 2]',
			category: 'Alignment'
		}
		gapExtension2: {
			description: 'gap extension penalty; a k-long gap costs min{O1+k*E1,O2+k*E2} 2 [default : 1]',
			category: 'Alignment'
		}
		ZDropScore1: {
			description: 'Z-drop score and inversion Z-drop score 1 [default : 400]',
			category: 'Alignment'
		}
		ZDropScore2: {
			description: 'Z-drop score and inversion Z-drop score 2 [default : 200]',
			category: 'Alignment'
		}
		minPeakDP: {
			description: 'minimal peak DP alignment score [default : 80]',
			category: 'Alignment'
		}
		finGTAG: {
			description: "how to find GT-AG. f:transcript strand, b:both strands, n:don't match GT-AG [default : 'n']",
			category: 'Alignment'
		}
		SAMoutput: {
			description: 'output in the SAM format (or in PAF) [default: true]',
			category: 'Output'
		}
		writeCIGARSup65535: {
			description: 'write CIGAR with >65535 ops at the CG tag [definault: false]',
			category: 'Output'
		}
		platformReads: {
			description: 'Type of plateform that produce reads [default: "ONT"]',
			category: 'Output'
		}
		csShort: {
			description: 'output the cs tag; true is "short" (if absent) ; false is "long" [none]',
			category: 'Output'
		}
		MDtag: {
			description: 'output the MD tag [definault: false]',
			category: 'Output'
		}
		CIGAROperator: {
			description: 'write =/X CIGAR operators [definault: false]',
			category: 'Output'
		}
		useSoftClipping: {
			description: 'use soft clipping for supplementary alignments',
			category: 'Output'
		}
		miniBatch: {
			description: 'minibatch size for mapping [500000000]',
			category: 'Output'
		}
		threads: {
			description: 'Sets the number of threads [default: 1]',
			category: 'System'
		}
		memory: {
			description: 'Sets the total memory to use ; with suffix M/G [default: (memoryByThreads*threads)M]',
			category: 'System'
		}
		memoryByThreads: {
			description: 'Sets the total memory to use (in M) [default: 768]',
			category: 'System'
		}
	}
}
