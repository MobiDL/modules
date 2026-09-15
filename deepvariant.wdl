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
		date: "2026-09-14"
	}

	input {
		String path_exe = "deepvariant"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
		String apptainer_img = "deepvariant:1.9.0"
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
		docker: "~{apptainer_img}"
		queue: "avx"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "deepvariant"]',
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
			description: 'Sets the apptainer image you want to use [default: deepvariant:1.9.0]',
			category: 'System'
		}
	}
}

task deepvariant {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.1.0"
		date: "2026-09-14"
	}

	input {
		String path_exe = "deepvariant"

		File bam
		File bai = bam + ".bai"

		String outputPath
		String subdir = ""
		String? name
		String suffix = ".dv"

		File refFasta
		File refFai = refFasta + ".fai"

		File? bed
		
		String model = "WES"

		Int threads = 12
		Int memoryByThreads = 768
		String? memory
		String apptainer_img = "deepvariant:1.9.0"
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String baseName = if defined(name) then name else sub(basename(bam),"\.(bam|cram)$","")
	String outputFile = "~{outputPath}/~{subdir}/~{baseName}~{suffix}.vcf"

	command <<<
		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} \
			--reads ~{bam} \
			--ref ~{refFasta} \
			--model_type ~{model} \
			~{default="" "--regions " + bed} \
			--num_shards ~{threads} \
			--output_vcf ~{outputFile}
	>>>

	runtime {
		bind_opt: "~{outputPath}/~{subdir}" + "," + "~{fasta}" + "," + "~{bam}" + "~{default='' ',' + bed}"
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
		docker: "~{apptainer_img}"
		queue: "avx"  ## https://cromwell.readthedocs.io/en/latest/RuntimeAttributes/
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "deepvariant"]',
			category: 'System'
		}
		bam: {
			description: 'Bam file.',
			category: 'Required'
		}
		bai: {
			description: 'Index for the alignement input file to recalibrate.',
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where bam will be generated.',
			category: 'Output path/name option'
		}
		subdir: {
			description: 'Subdirectory where to write output. [default: ""]',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(firstFile),subString,"")].',
			category: 'Output path/name option'
		}
		suffix: {
			description: 'Suffix to add for the output file (e.g sample.suffix.bam)[default: ".dv"]',
			category: 'Output path/name option'
		}
		refFasta: {
			description: 'Path to the reference file (format: fasta)',
			category: 'Required'
		}
		refFai: {
			description: 'Path to the reference file index (format: fai)',
			category: 'Required'
		}
		bed: {
			description: "Space-separated list of regions we want to process (bed or intervals)",
			category: 'Tool option'
		}
		model: {
			description: "Type of model to use for variant calling. (default : WES)",
			category: 'Tool option'
		}
		threads: {
			description: 'Sets the number of threads [default: 12]',
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
			description: 'Sets the apptainer image you want to use [default: deepvariant:1.9.0]',
			category: 'System'
		}
	}
}
