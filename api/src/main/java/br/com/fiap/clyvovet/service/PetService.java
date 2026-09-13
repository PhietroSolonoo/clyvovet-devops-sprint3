package br.com.fiap.clyvovet.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import br.com.fiap.clyvovet.dto.request.PetRequest;
import br.com.fiap.clyvovet.dto.response.PetResponse;
import br.com.fiap.clyvovet.enums.Especie;
import br.com.fiap.clyvovet.exception.ResourceNotFoundException;
import br.com.fiap.clyvovet.mapper.PetMapper;
import br.com.fiap.clyvovet.model.Pet;
import br.com.fiap.clyvovet.repository.PetRepository;
import br.com.fiap.clyvovet.repository.TutorRepository;

@Service
public class PetService {

    @Autowired
    private PetRepository petRepository;

    @Autowired
    private TutorRepository tutorRepository;

    @Autowired
    private PetMapper petMapper;

    @Transactional
    @CacheEvict(value = "pets", allEntries = true)
    public PetResponse create(PetRequest request) {
        if (!tutorRepository.existsById(request.getTutorId())) {
            throw new ResourceNotFoundException("Tutor não encontrado com id: " + request.getTutorId());
        }
        Pet pet = petMapper.toEntity(request);
        pet = petRepository.save(pet);
        return petMapper.toResponse(pet);
    }

    @Cacheable(value = "pets", key = "#id")
    public PetResponse findById(Long id) {
        Pet pet = petRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Pet não encontrado com id: " + id));
        return petMapper.toResponse(pet);
    }

    @Cacheable(value = "pets")
    public Page<PetResponse> findAll(Pageable pageable) {
        return petRepository.findAll(pageable)
                .map(petMapper::toResponse);
    }


    @Cacheable(value = "pets")
    public Page<PetResponse> findAll(Especie especie, String raca, Long tutorId, Pageable pageable) {
        Page<Pet> page;
        if (especie != null) {
            page = petRepository.findByEspecie(especie, pageable);
        } else if (raca != null && !raca.isEmpty()) {
            page = petRepository.findByRacaContainingIgnoreCase(raca, pageable);
        } else if (tutorId != null) {
            page = petRepository.findByTutorId(tutorId, pageable);
        } else {
            page = petRepository.findAll(pageable);
        }
        return page.map(petMapper::toResponse);
    }


    @Transactional
    @CacheEvict(value = "pets", allEntries = true)
    public PetResponse update(Long id, PetRequest request) {
        if (!petRepository.existsById(id)) {
            throw new ResourceNotFoundException("Pet não encontrado para atualização com id: " + id);
        }
        if (!tutorRepository.existsById(request.getTutorId())) {
            throw new ResourceNotFoundException("Tutor não encontrado com id: " + request.getTutorId());
        }
        Pet pet = petMapper.toEntity(request);
        pet.setId(id);
        pet = petRepository.save(pet);
        return petMapper.toResponse(pet);
    }

    @Transactional
    @CacheEvict(value = "pets", allEntries = true)
    public void delete(Long id) {
        if (!petRepository.existsById(id)) {
            throw new ResourceNotFoundException("Pet não encontrado para exclusão com id: " + id);
        }
        petRepository.deleteById(id);
    }
}