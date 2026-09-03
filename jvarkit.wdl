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
		version: "0.1.0"
		date: "2026-09-02"
	}

	input {
		String path_exe = "jvarkit"

		Int threads = 1
		Int memoryByThreads = 768
		String? memory
		String apptainer_img = "jvarkit:2026.04.30"
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	command <<<
		echo "jvarkit $(~{path_exe} --version)"
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
			description: 'Path used as executable [default: "jvarkit"]',
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
			description: 'Sets the apptainer image you want to use [default: jvarkit:2026.04.30]',
			category: 'System'
		}
	}
}

task vcfpolyx {
	meta {
		author: "Charles VAN GOETHEM"
		email: "c-vangoethem(at)chu-montpellier.fr"
		version: "0.1.0"
		date: "2026-09-03"
	}

	input {
		String path_exe = "jvarkit"

		File vcf
		String outputPath
		String subdir = ""
		String suffix = ".polyx"
		String? name
		
		File refFasta
		File refFai = refFasta + ".fai"
		File refDict = sub(refFasta, "(.*).(fa|fasta)", "$1.dict")

		Boolean bcf = false
		Boolean md5 = false
		Boolean skip = false
		Int repeats = -1
		String tag = "POLYX"


		Int threads = 1
		Int memoryByThreads = 768
		String? memory
		String apptainer_img = "jvarkit:2026.04.30"
	}

	String totalMem = if defined(memory) then memory else memoryByThreads*threads + "M"
	Boolean inGiga = (sub(totalMem,"([0-9]+)(M|G)", "$2") == "G")
	Int memoryValue = sub(totalMem,"([0-9]+)(M|G)", "$1")
	Int totalMemMb = if inGiga then memoryValue*1024 else memoryValue
	Int memoryByThreadsMb = floor(totalMemMb/threads)

	String ext = if bcf then ".bcf" else ".vcf"

	String baseName = if defined(name) then name else sub(basename(vcf),"\.(vcf|bcf)$","")
	String outputFile = "~{outputPath}/~{subdir}/~{baseName}~{suffix}~{ext}"

	command <<<
		if [[ ! -d $(dirname ~{outputFile}) ]]; then
			mkdir -p $(dirname ~{outputFile})
		fi

		~{path_exe} vcfpolyx \
			~{true="--bcf-output" false="" bcf} \
			~{true="--generate-vcf-md5" false="" md5} \
			~{true="--skip-filtered" false="" skip} \
			--tag ~{tag} \
			--max-repeats ~{repeats} \
			--reference ~{refFasta} \
			--out ~{outputFile} \
			~{vcf}
	>>>

	output {
		File output_vcf = outputFile
		File? output_md5 = outputFile + ".md5"
	}

	runtime {
		bind_opt: "~{outputPath}/~{subdir}" + "," + "~{refFasta}" + "," + "~{vcf}"
		cpu: "~{threads}"
		requested_memory_mb_per_core: "${memoryByThreadsMb}"
		docker: "~{apptainer_img}"
	}

	parameter_meta {
		path_exe: {
			description: 'Path used as executable [default: "jvarkit"]',
			category: 'System'
		}
		vcf: {
			description: "VCF/BCF file to tagged (extension: '.vcf|.bcf')",
			category: 'Required'
		}
		outputPath: {
			description: 'Output path where vcf will be generated.',
			category: 'Output path/name option'
		}
		subdir: {
			description: 'Subdirectory where to write output. [default: ""]',
			category: 'Output path/name option'
		}
		suffix: {
			description: 'Suffix to add on the output file (e.g. sample.suffix.vcf) [default: ".polyx"]',
			category: 'Output path/name option'
		}
		name: {
			description: 'Output file base name [default: sub(basename(vcf),"\.(vcf|bcf)$","")].',
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
		refDict: {
			description: 'Path to the reference file dict (format: dict)',
			category: 'Required'
		}
		bcf: {
			description: 'The current supported BCF version is : 2.1 which is not compatible with bcftools/htslib (default: false)',
			category: 'Tool option'
		}
		md5: {
			description: 'Generate MD5 checksum for VCF output. (default: false)',
			category: 'Tool option'
		}
		skip: {
			description: "Don't spend some time to calculate the tag if the variant is FILTERed (default: false)",
			category: 'Tool option'
		}
		repeats: {
			description: 'if number of repeated bases is greater or equal to "n" set a FILTER = (tag) (default: -1)',
			category: 'Tool option'
		}
		tag: {
			description: 'Tag used in INFO and FILTER columns. (default: "POLYX")',
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
			description: 'Sets the apptainer image you want to use [default: GATK4:4.6.2.0]',
			category: 'System'
		}
	}
}
