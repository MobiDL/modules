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
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.1.0"
		date: "2026-07-15"
	}

	input {
		String path_exe = "samtools"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
		String apptainer_img = "samtools:1.23.1"
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	command <<<
		~{path_exe} --version | head -1
	>>>

	output {
		String version = read_string(stdout())
	}

	runtime {
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
		docker: "~{apptainer_img}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "samtools"]',
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
			description: 'Sets the apptainer image you want to use [default: samtools:1.23.1]',
			category: 'System'
		}
	}
}

task sort {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.1.2"
		date: "2026-08-22"
	}

	input {
		String path_exe = "samtools"

		File bam
		String outputPath
		String subdir = ""
		String? name
		String suffix = ".sort"
		String format = "bam"

		Int compressionLevel = 6
		Boolean sortByReadName = false
		String? tag
		File? refFasta

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
		String apptainer_img = "samtools:1.23.1"
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else sub(basename(bam),"(\.sam|\.bam|\.cram)","")
	String outputFile = "~{outputPath}/~{subdir}/~{baseName}~{suffix}.~{format}"

	command <<<

		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} sort \
			-l ~{compressionLevel} \
			~{true="-n" false="" sortByReadName} \
			~{default="" "-t " + tag} \
			--output-fmt ~{format} \
			~{default="" "--reference \"" + refFasta + "\""} \
			--threads ~{threads - 1} \
			-m ~{memoryByThreadsMb}M \
			-o "~{outputFile}" \
			"~{bam}"

	>>>

	output {
		File outputFile = "~{outputFile}"
	}

	runtime {
		bind_opt: "~{outputPath}/~{subdir}" + "," + "~{bam}" + "," + "~{refFasta}"
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
		docker: "~{apptainer_img}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "samtools"]',
			category: 'System'
		}
		outputPath: {
			description: 'Output path where bam file was generated. [default: pwd()]',
			category: 'Tool option'
		}
        subdir: {
			description: 'Subdirectory where to write output. [default: ""]',
			category: 'Output path/name option'
        }
		name: {
			description: 'Name to use for output file name [default: sub(basename(in),"(\.bam|\.sam|\.cram)","")]',
			category: 'Tool option'
		}
		bam: {
			description: 'Bam/sam/cram file to sort.',
			category: 'Required'
		}
		suffix: {
			description: 'Suffix to add on the output file (e.g. sample.suffix.bam) [default: ".sort"]',
			category: 'Tool option'
		}
		format: {
			description: 'Specify a single output file format option [default: "bam"]',
			category: 'Tool option'
		}
		compressionLevel: {
			description: 'Specify compression level of the resulting file (from 0 to 9) [default: 6]',
			category: 'Tool option'
		}
		sortByReadName: {
			description: 'Sort by read name [default: false]',
			category: 'Tool option'
		}
		tag: {
			description: 'Sort by value of TAG. Uses position as secondary index (or read name if -n is set)',
			category: 'Tool option'
		}
		refFasta: {
			description: 'Reference sequence FASTA FILE',
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
			description: 'Sets the apptainer image you want to use [default: samtools:1.23.1]',
			category: 'System'
		}
	}
}
