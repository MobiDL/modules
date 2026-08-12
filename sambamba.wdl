version 1.0

# MobiDL 2.0 - MobiDL 2 is a collection of tools wrapped in WDL to be used in any WDL pipelines.
# Copyright (C) 2026 MoBiDiC
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
		authors: ["Olivier ARDOUIN", "Charles VAN GOETHEM"]
		email: "o-ardouin(at)chu-montpellier.fr"
		version: "0.1.0"
		date: "2026-07-15"
	}

	input {
		String path_exe = "sambamba"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
		String apptainer_img = "sambamba:1.0.1"
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	command <<<
		~{path_exe} --version 2>&1 | head -2 | tail -1
	>>>

	output {
		String version = read_string(stderr())
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
		docker: "~{apptainer_img}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "sambamba"]',
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
		apptainer_img: {
			description: 'Sets the apptainer image you want to use [default: sambamba:1.0.1]',
			category: 'System'
		}
	}
}

task markdup {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.1.3"
		date: "2026-08-22"
	}

	input {
		String path_exe = "sambamba"

		File bam
		String outputPath
		String subdir = ""
		String? sample
		String suffix = ".markdup"

		Boolean removeDuplicates = false
		Int compressionLevel = 6

		String? tempDir
		Int? hashTableSize
		Int? overflowListSize
		Int? sortBufferSize
		Int? bufferSize

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
		String apptainer_img = "sambamba:1.0.1"
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String sampleName = if defined(sample) then sample else sub(basename(bam),"(\.bam|\.sam|\.cram)","")
	String outputBam = "~{outputPath}/~{subdir}/~{sampleName}~{suffix}.bam"
	String outputBai = "~{outputPath}/~{subdir}/~{sampleName}~{suffix}.bam.bai"

	command <<<

		if [[ ! -d $(dirname ~{outputBam}) ]]; then
			mkdir -p $(dirname ~{outputBam})
		fi

		~{path_exe} markdup \
			~{true="--remove-duplicates" false="" removeDuplicates} \
			--nthreads ~{threads} \
			--compression-level ~{compressionLevel} \
			~{default="" "--tmpdir " + tempDir} \
			~{default="" "--hash-table-size " + hashTableSize} \
			~{default="" "--overflow-list-size " + overflowListSize} \
			~{default="" "--sort-buffer-size " + sortBufferSize} \
			~{default="" "--io-buffer-size " + bufferSize} \
			"~{bam}" "~{outputBam}"

	>>>

	output {
		File outputBam = "~{outputBam}"
		File outputBai = "~{outputBai}"
	}

	runtime {
		bind_opt: "~{outputPath}/~{subdir}" + "," + "~{bam}" + "~{default='' ',' + tempDir}"
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
		docker: "~{apptainer_img}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "sambamba"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where bam file was generated. [default: pwd()]',
			category: 'Output path/name option'
		}
        subdir: {
			description: 'Subdirectory where to write output. [default: ""]',
			category: 'Output path/name option'
        }
		sample: {
			description: 'Sample name to use for output file name [default: sub(basename(in),"(\.bam|\.sam|\.cram)","")]',
			category: 'Output path/name option'
		}
		bam: {
			description: 'Bam file to mark or remove duplicates.',
			category: 'Required'
		}
		suffix: {
			description: 'Suffix to add on the output file (e.g. sample.suffix.bam) [default: ".markdup"]',
			category: 'Output path/name option'
		}
		removeDuplicates: {
			description: 'Remove duplicates instead of just marking them [default: false]',
			category: 'Tool option'
		}
		compressionLevel: {
			description: 'Specify compression level of the resulting file (from 0 to 9) [default: 6]',
			category: 'Tool option'
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
		hashTableSize: {
			description: 'Size of hash table for finding read pairs',
			category: 'Tool option'
		}
		overflowListSize: {
			description: 'Size of the overflow list where reads, thrown from the hash table, get a second chance to meet their pairs',
			category: 'Tool option'
		}
		sortBufferSize: {
			description: 'Total amount of memory (in *megabytes*) used for sorting purposes',
			category: 'Tool option'
		}
		bufferSize: {
			description: 'Two buffers of BUFFER_SIZE *megabytes* each are used for reading and writing BAM during the second pass',
			category: 'Tool option'
		}
		apptainer_img: {
			description: 'Sets the apptainer image you want to use [default: sambamba:1.0.1]',
			category: 'System'
		}
	}
}

task sort {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.1.1"
		date: "2026-08-22"
	}

	input {
		String path_exe = "sambamba"

		File bam
		String outputPath
		String subdir = ""
		String? sample
		String suffix = ".sort"

		String? filter
		Boolean? sortByReadName

		Int compressionLevel = 6
		Boolean uncompressedChuncks = false

		String? tempDir

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
		String apptainer_img = "sambamba:1.0.1"
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String sampleName = if defined(sample) then sample else sub(basename(bam),"(\.bam|\.sam|\.cram)","")
	String outputFile = "~{outputPath}/~{subdir}/~{sampleName}~{suffix}.bam"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} sort \
			--nthreads ~{threads} \
			~{default="" "--tmpdir " + tempDir} \
			~{default="" "--memory-limit " + memory} \
			~{default="" "--filter " + filter} \
			~{default="" true="--sort-by-name" false="--natural-sort" sortByReadName} \
			--compression-level ~{compressionLevel} \
			~{true="--uncompressed-chunks" false="" uncompressedChuncks} \
			--out "~{outputFile}" \
			"~{bam}"

	>>>

	output {
		File outputBam = outputFile
		File outputBai = outputFile + ".bai"
	}

	runtime {
		bind_opt: "~{outputPath}/~{subdir}" + "," + "~{bam}" + "~{default='' ',' + tempDir}"
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
		docker: "~{apptainer_img}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "sambamba"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where bam file was generated. [default: pwd()]',
			category: 'Output path/name option'
		}
        subdir: {
			description: 'Subdirectory where to write output. [default: ""]',
			category: 'Output path/name option'
        }
		sample: {
			description: 'Sample name to use for output file name [default: sub(basename(in),"(\.bam|\.sam|\.cram)","")]',
			category: 'Output path/name option'
		}
		bam: {
			description: 'Bam file to sort.',
			category: 'Required'
		}
		suffix: {
			description: 'Suffix to add on the output file (e.g. sample.suffix.bam) [default: ".sort"]',
			category: 'Output path/name option'
		}
		compressionLevel: {
			description: 'Specify compression level of the resulting file (from 0 to 9) [default: 6]',
			category: 'Tool option'
		}
		tempDir: {
			description: 'Directory for storing intermediate files; default is system directory for temporary files',
			category: 'Tool option'
		}
		filter: {
			description: 'Keep only reads that satisfy FILTER',
			category: 'Tool option'
		}
		sortByReadName: {
			description: 'Sort by read name instead of coordinate (true: lexicographical; false: natural) (default: null)',
			category: 'Tool option'
		}
		uncompressedChuncks: {
			description: 'Write sorted chunks as uncompressed BAM (default is writing with compression level 1), that might be faster in some cases but uses more disk space',
			category: 'Tool option'
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
		apptainer_img: {
			description: 'Sets the apptainer image you want to use [default: sambamba:1.0.1]',
			category: 'System'
		}
	}
}
