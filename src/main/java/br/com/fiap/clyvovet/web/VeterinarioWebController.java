package br.com.fiap.clyvovet.web;

import java.util.EnumSet;
import java.util.List;
import java.util.Set;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import br.com.fiap.clyvovet.dto.web.AtendimentoConsultaForm;
import br.com.fiap.clyvovet.enums.StatusConsulta;
import br.com.fiap.clyvovet.exception.ResourceNotFoundException;
import br.com.fiap.clyvovet.model.Consulta;
import br.com.fiap.clyvovet.repository.ConsultaRepository;
import br.com.fiap.clyvovet.security.UsuarioAutenticado;
import br.com.fiap.clyvovet.service.AtendimentoConsultaService;
import jakarta.validation.Valid;

@Controller
@RequestMapping("/app/veterinario")
public class VeterinarioWebController {

    private static final Set<StatusConsulta> STATUS_PENDENTES =
            EnumSet.of(StatusConsulta.AGENDADA, StatusConsulta.CONFIRMADA, StatusConsulta.EM_ANDAMENTO);

    @Autowired
    private ConsultaRepository consultaRepository;

    @Autowired
    private AtendimentoConsultaService atendimentoConsultaService;

    @GetMapping("/agenda")
    public String agenda(@AuthenticationPrincipal UsuarioAutenticado usuario, Model model) {
        List<Consulta> consultas = consultaRepository.findByVeterinarioIdOrderByDataHoraAsc(usuario.getVeterinarioId())
                .stream()
                .filter(consulta -> STATUS_PENDENTES.contains(consulta.getStatusConsulta()))
                .toList();
        model.addAttribute("consultas", consultas);
        return "veterinario/agenda";
    }

    @GetMapping("/consultas/{id}/atender")
    public String atenderForm(@PathVariable Long id, @AuthenticationPrincipal UsuarioAutenticado usuario, Model model) {
        Consulta consulta = buscarConsultaDoVeterinario(id, usuario.getVeterinarioId());
        model.addAttribute("consulta", consulta);
        model.addAttribute("form", new AtendimentoConsultaForm());
        return "veterinario/atender";
    }

    @PostMapping("/consultas/{id}/atender")
    public String atender(@PathVariable Long id, @Valid @ModelAttribute("form") AtendimentoConsultaForm form,
                           BindingResult result, @AuthenticationPrincipal UsuarioAutenticado usuario, Model model,
                           RedirectAttributes redirectAttributes) {
        Consulta consulta = buscarConsultaDoVeterinario(id, usuario.getVeterinarioId());
        if (result.hasErrors()) {
            model.addAttribute("consulta", consulta);
            return "veterinario/atender";
        }
        atendimentoConsultaService.atender(usuario.getVeterinarioId(), id, form);
        redirectAttributes.addFlashAttribute("mensagem", "Consulta concluída com sucesso!");
        return "redirect:/app/veterinario/agenda";
    }

    private Consulta buscarConsultaDoVeterinario(Long consultaId, Long veterinarioId) {
        Consulta consulta = consultaRepository.findById(consultaId)
                .orElseThrow(() -> new ResourceNotFoundException("Consulta", consultaId));
        if (!consulta.getVeterinario().getId().equals(veterinarioId)) {
            throw new AccessDeniedException("Esta consulta não pertence ao veterinário autenticado");
        }
        return consulta;
    }
}
